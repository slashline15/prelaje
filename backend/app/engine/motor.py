"""
Ponto de entrada do motor de cálculo.
Orquestra o pipeline completo: cargas → esforços → verificações → quantitativos.
Rastreável a: docs/dominio/01_matriz_dominio_tecnico.md §4 (Pipeline)
"""

import math
from ..schemas import (
    DadosLaje, ResultadoDimensionamento, ModoCalculo, TipoApoio,
    VerificacaoELU, VerificacaoELS, Quantitativos,
)
from .materiais import get_vigota, modulo_elasticidade_secante
from .cargas import calcular_cargas
from .analise_estrutural import esforcos_biapoiada, esforcos_continua
from .verificacoes import (
    calcular_secao_t, verificar_flexao,
    verificar_cisalhamento, verificar_flecha,
)


PESO_TELA_Q92 = 5.17  # kg/m² — referência padrão (Q-92)


def calcular(dados: DadosLaje) -> ResultadoDimensionamento:
    """
    Motor principal de dimensionamento.
    """
    alertas: list[str] = []
    erros:   list[str] = []

    # ------------------------------------------------------------------
    # 1. Carregar dados da vigota
    # ------------------------------------------------------------------
    vigota = get_vigota(dados.codigo_vigota)

    if dados.vao > vigota.vao_max:
        erros.append(
            f"Vão {dados.vao} m excede o máximo de {vigota.vao_max} m para {vigota.codigo}. "
            "Selecione uma vigota de maior altura ou reduza o vão."
        )
        return _resultado_bloqueado(dados, erros)

    # ------------------------------------------------------------------
    # 2. Cargas
    # ------------------------------------------------------------------
    cargas = calcular_cargas(
        uso=dados.uso.value,
        vigota=vigota,
        h_capa_m=dados.h_capa,
        h_enc_m=dados.h_enchimento,
        g_revestimento=dados.g_revestimento,
    )

    # ------------------------------------------------------------------
    # 3. Seção transversal
    # ------------------------------------------------------------------
    secao = calcular_secao_t(vigota, dados.h_capa, dados.vao)

    # ------------------------------------------------------------------
    # 4. Análise estrutural
    # ------------------------------------------------------------------
    Ecs   = modulo_elasticidade_secante(dados.fck) * 1000.0  # kN/m²
    EI    = Ecs * secao.Ic  # kN·m²

    if dados.tipo_apoio == TipoApoio.BIAPOIADA:
        esforcos = esforcos_biapoiada(cargas.w_sd, dados.vao)
    else:
        n_vaos = 2 if dados.tipo_apoio == TipoApoio.CONTINUA_2 else 3
        esforcos = esforcos_continua(
            w_sd_list=[cargas.w_sd] * n_vaos,
            L_list=[dados.vao] * n_vaos,
            EI_list=[EI] * n_vaos,
        )

    # ------------------------------------------------------------------
    # 5. Verificações ELU
    # ------------------------------------------------------------------
    try:
        res_flexao = verificar_flexao(
            msd=esforcos.msd_max,
            secao=secao,
            fck_mpa=dados.fck,
            classe_aco=dados.classe_aco.value,
        )
        alertas.extend(res_flexao.alertas)
    except ValueError as exc:
        erros.append(str(exc))
        return _resultado_bloqueado(dados, erros)

    res_cis = verificar_cisalhamento(
        vsd=esforcos.vsd_max,
        secao=secao,
        fck_mpa=dados.fck,
        As_cm2=res_flexao.as_calculado_cm2,
    )
    if not res_cis.aprovado:
        erros.append(res_cis.alerta)

    elu = VerificacaoELU(
        msd=esforcos.msd_max,
        vsd=esforcos.vsd_max,
        as_calculado=res_flexao.as_calculado_cm2,
        as_minimo=res_flexao.as_minimo_cm2,
        xd=res_flexao.xd,
        aprovado_flexao=res_flexao.aprovado,
        aprovado_cisalhamento=res_cis.aprovado,
        aprovado_armadura_minima=(
            res_flexao.as_calculado_cm2 >= res_flexao.as_minimo_cm2
        ),
    )

    # ------------------------------------------------------------------
    # 6. Verificações ELS
    # ------------------------------------------------------------------
    res_flecha = verificar_flecha(
        w_ser=cargas.w_ser,
        L=dados.vao,
        secao=secao,
        fck_mpa=dados.fck,
        As_cm2=res_flexao.as_calculado_cm2,
    )
    if not res_flecha.aprovado:
        alertas.append(res_flecha.alerta)

    els = VerificacaoELS(
        flecha_imediata=res_flecha.flecha_imediata_cm,
        flecha_diferida=res_flecha.flecha_diferida_cm,
        flecha_total=res_flecha.flecha_total_cm,
        flecha_limite=res_flecha.flecha_limite_cm,
        aprovado=res_flecha.aprovado,
    )

    # ------------------------------------------------------------------
    # 7. Quantitativos
    # ------------------------------------------------------------------
    n_vigotas = math.ceil(dados.largura_total / (vigota.intereixo / 100.0))
    s_enc_m   = 1.25  # comprimento padrão da peça de enchimento (m)
    n_enc     = math.ceil(dados.largura_total / (vigota.intereixo / 100.0))
    n_enc    *= math.ceil(dados.vao / s_enc_m)

    # Volume da capa (desconta nervuras)
    b_nerv_m  = vigota.b_nerv / 100.0
    vol_capa  = (dados.largura_total * dados.vao * dados.h_capa
                 - n_vigotas * dados.vao * b_nerv_m * dados.h_capa)
    vol_capa  = max(vol_capa, 0.0)

    peso_tela = PESO_TELA_Q92 * dados.largura_total * dados.vao

    quant = Quantitativos(
        n_vigotas=n_vigotas,
        n_enchimento=n_enc,
        volume_capa_m3=round(vol_capa, 3),
        peso_tela_kg=round(peso_tela, 1),
    )

    # ------------------------------------------------------------------
    # 8. Status geral
    # ------------------------------------------------------------------
    aprovado = (
        elu.aprovado_flexao
        and elu.aprovado_cisalhamento
        and elu.aprovado_armadura_minima
        and len(erros) == 0
    )

    return ResultadoDimensionamento(
        modo=dados.modo,
        codigo_vigota=vigota.codigo,
        g_k=cargas.g_k,
        q_k=cargas.q_k,
        q_sd=cargas.q_sd,
        q_ser=cargas.q_ser,
        elu=elu,
        els=els,
        quantitativos=quant,
        aprovado=aprovado,
        alertas=alertas,
        erros=erros,
        parametros_validade={
            "fck": dados.fck,
            "aco": dados.classe_aco.value,
            "vigota": vigota.codigo,
            "intereixo_cm": vigota.intereixo,
        },
    )


def _resultado_bloqueado(
    dados: DadosLaje,
    erros: list[str],
) -> ResultadoDimensionamento:
    """Retorna resultado com aprovado=False quando há bloqueio de segurança."""
    return ResultadoDimensionamento(
        modo=dados.modo,
        codigo_vigota=dados.codigo_vigota,
        g_k=0, q_k=0, q_sd=0, q_ser=0,
        quantitativos=Quantitativos(
            n_vigotas=0, n_enchimento=0,
            volume_capa_m3=0, peso_tela_kg=0,
        ),
        aprovado=False,
        alertas=[],
        erros=erros,
    )
