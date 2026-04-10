"""
Ponto de entrada do motor de cálculo.
Orquestra o pipeline completo: cargas → esforços → verificações → quantitativos.
Rastreável a: docs/dominio/01_matriz_dominio_tecnico.md §4 (Pipeline)
"""

import math
from ..schemas import (
    DadosLaje, ResultadoDimensionamento, ModoCalculo, TipoApoio,
    VerificacaoELU, VerificacaoELS, Quantitativos,
    ResultadoCatalogo, ArmaduraReforco,
    MensagemSistema, SeveridadeMensagem, StatusDimensionamento,
)
from .materiais import get_vigota, modulo_elasticidade_secante
from .cargas import calcular_cargas
from .catalogo import (
    CATALOGO_VERSION,
    CatalogoLookupError,
    buscar_solucao_catalogo,
    sobrecarga_catalogo_kgf_m2,
)
from .analise_estrutural import esforcos_biapoiada, esforcos_continua
from .orcamento import calcular_orcamento_preliminar
from .verificacoes import (
    calcular_secao_t, verificar_flexao,
    verificar_cisalhamento, verificar_flecha,
)


PESO_TELA_Q92 = 5.17  # kg/m² — referência padrão (Q-92)
ENGINE_VERSION = "0.3.0"


def _erro(
    code: str,
    message: str,
    *,
    value: float | None = None,
    limit: float | None = None,
) -> MensagemSistema:
    return MensagemSistema(
        code=code,
        severity=SeveridadeMensagem.ERROR,
        message=message,
        value=value,
        limit=limit,
    )


def _alerta(
    code: str,
    message: str,
    *,
    value: float | None = None,
    limit: float | None = None,
) -> MensagemSistema:
    return MensagemSistema(
        code=code,
        severity=SeveridadeMensagem.WARNING,
        message=message,
        value=value,
        limit=limit,
    )


def _calcular_quantitativos(dados: DadosLaje, b_nerv_m: float) -> Quantitativos:
    n_vigotas = math.ceil(dados.largura_total / dados.intereixo)
    s_enc_m = 1.25  # comprimento padrão da peça de enchimento (m)
    n_colunas_enchimento = max(n_vigotas - 1, 0)
    n_enc = n_colunas_enchimento * math.ceil(dados.vao / s_enc_m)

    vol_capa = (
        dados.largura_total * dados.vao * dados.h_capa
        - n_vigotas * dados.vao * b_nerv_m * dados.h_capa
    )
    vol_capa = max(vol_capa, 0.0)
    peso_tela = PESO_TELA_Q92 * dados.largura_total * dados.vao

    return Quantitativos(
        n_vigotas=n_vigotas,
        n_enchimento=n_enc,
        volume_capa_m3=round(vol_capa, 3),
        peso_tela_kg=round(peso_tela, 1),
    )


def calcular(dados: DadosLaje) -> ResultadoDimensionamento:
    """
    Motor principal de dimensionamento.
    """
    alertas: list[MensagemSistema] = []
    erros: list[MensagemSistema] = []

    # ------------------------------------------------------------------
    # 1. Carregar dados da vigota
    # ------------------------------------------------------------------
    vigota = get_vigota(dados.codigo_vigota, modo=dados.modo.value)
    b_nerv_m = vigota.b_nerv / 100.0

    intereixo_catalogo_m = vigota.intereixo / 100.0
    if abs(dados.intereixo - intereixo_catalogo_m) > 0.005:
        erros.append(
            _erro(
                "INTEREIXO_INCOMPATIVEL",
                f"Intereixo informado ({dados.intereixo:.3f} m) é incompatível com "
                f"a vigota {vigota.codigo} ({intereixo_catalogo_m:.3f} m).",
                value=dados.intereixo,
                limit=intereixo_catalogo_m,
            )
        )
        return _resultado_bloqueado(dados, erros)

    if dados.vao > vigota.vao_max:
        erros.append(
            _erro(
                "L_MAX_CATALOGO",
                f"Vão {dados.vao} m excede o máximo de {vigota.vao_max} m para {vigota.codigo}. "
                "Selecione uma vigota de maior altura ou reduza o vão.",
                value=dados.vao,
                limit=vigota.vao_max,
            )
        )
        return _resultado_bloqueado(dados, erros)

    # ------------------------------------------------------------------
    # 2. Cargas
    # ------------------------------------------------------------------
    cargas = calcular_cargas(
        uso=dados.uso.value,
        intereixo_m=dados.intereixo,
        b_nerv_m=b_nerv_m,
        h_capa_m=dados.h_capa,
        h_enc_m=dados.h_enchimento,
        g_revestimento=dados.g_revestimento,
    )
    quant = _calcular_quantitativos(dados, b_nerv_m)

    if dados.modo == ModoCalculo.CATALOGO:
        # Em catálogo, usar a capa mínima da vigota se o usuário informou menos
        capa_catalogo_cm = max(dados.h_capa * 100.0, vigota.capa_min)
        if capa_catalogo_cm > dados.h_capa * 100.0 + 0.1:
            alertas.append(
                _alerta(
                    "CAPA_AJUSTADA_CATALOGO",
                    f"Capa ajustada de {dados.h_capa*100:.1f} cm para "
                    f"{capa_catalogo_cm:.1f} cm (mínimo da vigota {vigota.codigo}).",
                    value=dados.h_capa * 100.0,
                    limit=capa_catalogo_cm,
                )
            )

        # Catálogos brasileiros informam sobrecarga útil (exclui peso próprio)
        sobrecarga = sobrecarga_catalogo_kgf_m2(dados.g_revestimento, cargas.q_k)

        try:
            solucao = buscar_solucao_catalogo(
                vigota.codigo,
                dados.fck,
                dados.intereixo * 100.0,
                capa_catalogo_cm,
                dados.vao,
                sobrecarga,
            )
        except CatalogoLookupError as exc:
            erros.append(
                _erro(
                    exc.code,
                    exc.message,
                    value=exc.value,
                    limit=exc.limit,
                )
            )
            return _resultado_bloqueado(
                dados,
                erros,
                cargas=cargas,
                quantitativos=quant,
                parametros_validade={
                    "fck": dados.fck,
                    "aco": dados.classe_aco.value,
                    "vigota": vigota.codigo,
                    "intereixo_cm": round(dados.intereixo * 100.0, 1),
                    "intereixo_catalogo_cm": vigota.intereixo,
                    "catalog_version": CATALOGO_VERSION,
                },
            )

        alertas.append(
            _alerta(
                "CATALOGO_REFERENCIA",
                "Resultado de catálogo baseado em matriz de referência. "
                "Homologue a tabela com fabricante antes de uso comercial.",
            )
        )

        catalogo_resultado = ResultadoCatalogo(
            vao_tabelado=solucao.vao_tabelado,
            carga_total_kgf_m2=solucao.carga_total_kgf_m2,
            reforco=(
                None
                if solucao.reforco is None
                else ArmaduraReforco(
                    diametro_mm=solucao.reforco.diametro_mm,
                    quantidade=solucao.reforco.quantidade,
                    as_total_cm2=solucao.reforco.as_total_cm2,
                )
            ),
            escoramento_max_m=solucao.escoramento_max_m,
            dentro_do_catalogo=solucao.dentro_do_catalogo,
        )

        resultado = ResultadoDimensionamento(
            modo=dados.modo,
            codigo_vigota=vigota.codigo,
            g_k=cargas.g_k,
            q_k=cargas.q_k,
            q_sd=cargas.q_sd,
            q_ser=cargas.q_ser,
            catalogo=catalogo_resultado,
            quantitativos=quant,
            status=StatusDimensionamento.APPROVED_WITH_WARNINGS,
            aprovado=True,
            alertas=alertas,
            erros=[],
            engine_version=ENGINE_VERSION,
            parametros_validade={
                "fck": dados.fck,
                "aco": dados.classe_aco.value,
                "vigota": vigota.codigo,
                "intereixo_cm": round(dados.intereixo * 100.0, 1),
                "intereixo_catalogo_cm": vigota.intereixo,
                "catalog_version": CATALOGO_VERSION,
            },
        )
        try:
            resultado.orcamento = calcular_orcamento_preliminar(
                dados,
                resultado,
                quant,
                vigota,
                regiao=dados.regiao,
            )
        except Exception:
            resultado.orcamento = None
        return resultado

    # ------------------------------------------------------------------
    # 3. Seção transversal
    # ------------------------------------------------------------------
    secao = calcular_secao_t(vigota, dados.h_capa, dados.vao, dados.intereixo)

    # ------------------------------------------------------------------
    # 4. Análise estrutural
    # ------------------------------------------------------------------
    Ecs   = modulo_elasticidade_secante(dados.fck) * 1000.0  # kN/m²
    EI    = Ecs * secao.Ic  # kN·m²

    if dados.tipo_apoio == TipoApoio.BIAPOIADA:
        esforcos = esforcos_biapoiada(cargas.w_sd, dados.vao)
        esforcos_servico = esforcos_biapoiada(cargas.w_ser, dados.vao)
    else:
        n_vaos = 2 if dados.tipo_apoio == TipoApoio.CONTINUA_2 else 3
        esforcos = esforcos_continua(
            w_sd_list=[cargas.w_sd] * n_vaos,
            L_list=[dados.vao] * n_vaos,
            EI_list=[EI] * n_vaos,
        )
        esforcos_servico = esforcos_continua(
            w_sd_list=[cargas.w_ser] * n_vaos,
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
        for alerta in res_flexao.alertas:
            alertas.append(_alerta("FLEXAO_AVISO", alerta))
    except ValueError as exc:
        erros.append(_erro("FLEXAO_NAO_DIMENSIONAVEL", str(exc)))
        return _resultado_bloqueado(dados, erros)

    res_cis = verificar_cisalhamento(
        vsd=esforcos.vsd_max,
        secao=secao,
        fck_mpa=dados.fck,
        As_cm2=res_flexao.as_calculado_cm2,
    )
    if not res_cis.aprovado:
        erros.append(
            _erro(
                "VSD_GT_VRD1",
                res_cis.alerta,
                value=esforcos.vsd_max,
                limit=res_cis.vrd1,
            )
        )

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
        ma_ser=esforcos_servico.msd_max,
    )
    if dados.tipo_apoio != TipoApoio.BIAPOIADA:
        alertas.append(
            _alerta(
                "ELS_CONTINUA_SIMPLIFICADO",
                "Flecha em laje continua ainda usa formulacao simplificada para viga com carga distribuida. "
                "O momento de servico foi alinhado com a analise continua, mas a deflexao ainda deve ser validada "
                "com casos manuais antes de uso definitivo.",
            )
        )
    if not res_flecha.aprovado:
        alertas.append(
            _alerta(
                "DELTA_GT_LIMIT",
                res_flecha.alerta,
                value=res_flecha.flecha_total_cm,
                limit=res_flecha.flecha_limite_cm,
            )
        )

    els = VerificacaoELS(
        flecha_imediata=res_flecha.flecha_imediata_cm,
        flecha_diferida=res_flecha.flecha_diferida_cm,
        flecha_total=res_flecha.flecha_total_cm,
        flecha_limite=res_flecha.flecha_limite_cm,
        aprovado=res_flecha.aprovado,
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
    status = (
        StatusDimensionamento.REJECTED
        if not aprovado
        else StatusDimensionamento.APPROVED_WITH_WARNINGS
        if alertas
        else StatusDimensionamento.APPROVED
    )

    resultado = ResultadoDimensionamento(
        modo=dados.modo,
        codigo_vigota=vigota.codigo,
        g_k=cargas.g_k,
        q_k=cargas.q_k,
        q_sd=cargas.q_sd,
        q_ser=cargas.q_ser,
        elu=elu,
        els=els,
        quantitativos=quant,
        status=status,
        aprovado=aprovado,
        alertas=alertas,
        erros=erros,
        engine_version=ENGINE_VERSION,
        parametros_validade={
            "fck": dados.fck,
            "aco": dados.classe_aco.value,
            "vigota": vigota.codigo,
            "intereixo_cm": round(dados.intereixo * 100.0, 1),
            "intereixo_catalogo_cm": vigota.intereixo,
        },
    )
    if not aprovado:
        erros.append(
            _erro(
                "DIMENSIONAMENTO_REJEITADO",
                "Resultado rejeitado pelas verificações do motor.",
            )
        )
        return _resultado_bloqueado(
            dados,
            erros,
            cargas=cargas,
            parametros_validade={
                "fck": dados.fck,
                "aco": dados.classe_aco.value,
                "vigota": vigota.codigo,
                "intereixo_cm": round(dados.intereixo * 100.0, 1),
                "intereixo_catalogo_cm": vigota.intereixo,
            },
        )

    try:
        resultado.orcamento = calcular_orcamento_preliminar(
            dados,
            resultado,
            quant,
            vigota,
            regiao=dados.regiao,
        )
    except Exception:
        resultado.orcamento = None
    return resultado


def _resultado_bloqueado(
    dados: DadosLaje,
    erros: list[MensagemSistema],
    *,
    cargas=None,
    quantitativos: Quantitativos | None = None,
    parametros_validade: dict | None = None,
) -> ResultadoDimensionamento:
    """Retorna resultado com aprovado=False quando há bloqueio de segurança."""
    return ResultadoDimensionamento(
        modo=dados.modo,
        codigo_vigota=dados.codigo_vigota,
        g_k=0 if cargas is None else cargas.g_k,
        q_k=0 if cargas is None else cargas.q_k,
        q_sd=0 if cargas is None else cargas.q_sd,
        q_ser=0 if cargas is None else cargas.q_ser,
        quantitativos=quantitativos
        or Quantitativos(
            n_vigotas=0, n_enchimento=0,
            volume_capa_m3=0, peso_tela_kg=0,
        ),
        status=StatusDimensionamento.REJECTED,
        aprovado=False,
        alertas=[],
        erros=erros,
        engine_version=ENGINE_VERSION,
        parametros_validade=parametros_validade or {},
    )
