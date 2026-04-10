"""
Geração de PDF de relatório/memorial preliminar.
"""

from __future__ import annotations

from io import BytesIO

from reportlab.lib.pagesizes import A4
from reportlab.pdfgen import canvas

from ..schemas import DadosLaje, ResultadoDimensionamento


SAFE_HARBOR = [
    "Ferramenta para estudos preliminares. Nao substitui projeto estrutural final.",
    "Projeto final deve ser validado por Engenheiro Civil habilitado com ART.",
    "Vigas de apoio, pilares e fundacoes nao sao verificados por esta ferramenta.",
    "Consulte o projeto de escoramento e os catalogos oficiais do fabricante.",
]


def gerar_relatorio_pdf(dados: DadosLaje, resultado: ResultadoDimensionamento) -> bytes:
    buffer = BytesIO()
    pdf = canvas.Canvas(buffer, pagesize=A4, pageCompression=0)
    width, height = A4
    y = height - 40
    left = 40

    def nova_pagina() -> None:
        nonlocal y
        pdf.showPage()
        y = height - 40

    def linha(texto: str, *, tamanho: int = 10, salto: int = 14) -> None:
        nonlocal y
        if y < 50:
            nova_pagina()
        pdf.setFont("Helvetica", tamanho)
        pdf.drawString(left, y, texto[:110])
        y -= salto

    pdf.setTitle("Relatorio Preliminar - Prelaje")
    linha("Prelaje - Relatorio Preliminar de Dimensionamento", tamanho=14, salto=20)
    linha(f"Modo: {resultado.modo.value} | Status: {resultado.status.value}")
    linha(f"Engine: {resultado.engine_version}")
    linha("")

    linha("Normas e validade", tamanho=12, salto=18)
    for norma in resultado.normas_utilizadas:
        linha(f"- {norma}")
    for item in SAFE_HARBOR:
        linha(f"- {item}")
    linha("")

    linha("Parametros de entrada", tamanho=12, salto=18)
    linha(f"Vao livre: {dados.vao:.2f} m")
    linha(f"Intereixo: {dados.intereixo:.2f} m")
    linha(f"Altura enchimento: {dados.h_enchimento:.2f} m")
    linha(f"Espessura da capa: {dados.h_capa:.2f} m")
    linha(f"Largura total: {dados.largura_total:.2f} m")
    linha(f"Vigota: {dados.codigo_vigota} | fck: {dados.fck:.1f} MPa | Aco: {dados.classe_aco.value}")
    linha(f"Uso: {dados.uso.value} | Revestimento: {dados.g_revestimento:.2f} kN/m2 | Regiao: {dados.regiao}")
    linha("")

    linha("Carregamentos", tamanho=12, salto=18)
    linha(f"g_k = {resultado.g_k:.4f} kN/m2")
    linha(f"q_k = {resultado.q_k:.4f} kN/m2")
    linha(f"q_sd = {resultado.q_sd:.4f} kN/m2")
    linha(f"q_ser = {resultado.q_ser:.4f} kN/m2")
    linha("")

    if resultado.catalogo is not None:
        linha("Resultado do modo catalogo", tamanho=12, salto=18)
        linha(f"Vao tabelado: {resultado.catalogo.vao_tabelado:.2f} m")
        linha(f"Carga total: {resultado.catalogo.carga_total_kgf_m2:.1f} kgf/m2")
        if resultado.catalogo.reforco is None:
            linha("Reforco adicional: sem reforco")
        else:
            linha(
                f"Diametro: {resultado.catalogo.reforco.diametro_mm:.1f} mm | "
                f"Quantidade: {resultado.catalogo.reforco.quantidade} | "
                f"As: {resultado.catalogo.reforco.as_total_cm2:.3f} cm2"
            )
        linha(f"Escoramento maximo: {resultado.catalogo.escoramento_max_m:.2f} m")
        linha("")

    if resultado.elu is not None:
        linha("Verificacoes ELU", tamanho=12, salto=18)
        linha(f"Msd = {resultado.elu.msd:.3f} kN.m | Vsd = {resultado.elu.vsd:.3f} kN")
        linha(
            f"As calc = {resultado.elu.as_calculado:.3f} cm2 | "
            f"As min = {resultado.elu.as_minimo:.3f} cm2 | x/d = {resultado.elu.xd:.4f}"
        )
        linha(
            "Flexao: "
            f"{'OK' if resultado.elu.aprovado_flexao else 'NAO'} | "
            f"Cisalhamento: {'OK' if resultado.elu.aprovado_cisalhamento else 'NAO'} | "
            f"As_min: {'OK' if resultado.elu.aprovado_armadura_minima else 'NAO'}"
        )
        linha("")

    if resultado.els is not None:
        linha("Verificacoes ELS", tamanho=12, salto=18)
        linha(
            f"Flecha imediata = {resultado.els.flecha_imediata:.3f} cm | "
            f"Diferida = {resultado.els.flecha_diferida:.3f} cm"
        )
        linha(
            f"Flecha total = {resultado.els.flecha_total:.3f} cm | "
            f"Limite = {resultado.els.flecha_limite:.3f} cm | "
            f"{'OK' if resultado.els.aprovado else 'ALERTA'}"
        )
        linha("")

    if resultado.aprovado:
        linha("Quantitativos preliminares", tamanho=12, salto=18)
        linha(f"Numero de vigotas: {resultado.quantitativos.n_vigotas}")
        linha(f"Numero de enchimentos: {resultado.quantitativos.n_enchimento}")
        linha(f"Volume de capa: {resultado.quantitativos.volume_capa_m3:.3f} m3")
        linha(f"Peso de tela soldada: {resultado.quantitativos.peso_tela_kg:.1f} kg")
        linha("")

    if resultado.aprovado and resultado.orcamento is not None:
        linha("Orcamento preliminar (referencia, sem compromisso)", tamanho=12, salto=18)
        linha("Precos de referencia regional. Nao constitui proposta comercial.")
        linha(f"Regiao de referencia: {resultado.orcamento.regiao}")
        linha(f"Subtotal direto: R$ {resultado.orcamento.resumo.subtotal_direto:.2f}")
        linha(f"Subtotal materiais: R$ {resultado.orcamento.resumo.subtotal_materiais:.2f}")
        linha(f"Subtotal mao de obra: R$ {resultado.orcamento.resumo.subtotal_mao_obra:.2f}")
        linha(f"Subtotal indiretos: R$ {resultado.orcamento.resumo.subtotal_indiretos:.2f}")
        linha(
            f"Total geral: R$ {resultado.orcamento.resumo.total_geral:.2f} | "
            f"Custo unitario: R$ {resultado.orcamento.resumo.custo_unitario_m2:.2f}/m2"
        )
        for item in resultado.orcamento.itens[:8]:
            linha(
                f"{item.codigo}: {item.quantidade_compra:.3f} {item.unidade_compra} x "
                f"R$ {item.preco_unitario:.2f} = R$ {item.custo_total:.2f}"
            )
        if len(resultado.orcamento.itens) > 8:
            linha(f"... {len(resultado.orcamento.itens) - 8} itens adicionais no resumo JSON da API")
        if resultado.orcamento.alertas:
            linha("Alertas de orcamento:")
            for alerta in resultado.orcamento.alertas:
                linha(f"- {alerta}")
        linha("")

    if resultado.aprovado and resultado.orcamento is not None and resultado.orcamento.resumo_comercial is not None:
        rc = resultado.orcamento.resumo_comercial
        linha("RESUMO COMERCIAL", tamanho=14, salto=20)
        linha(f"Area da laje: {rc.area_laje_m2:.2f} m2 | Regiao: {rc.regiao}")
        linha(
            f"TOTAL: R$ {rc.total_geral:.2f} | "
            f"Custo/m2: R$ {rc.custo_unitario_m2:.2f}/m2"
        )
        linha("")
        linha("Top 5 Insumos:", tamanho=11, salto=14)
        for indice, item in enumerate(rc.top_insumos, start=1):
            linha(f"{indice}. {item.codigo}: R$ {item.valor:.2f}")
        linha("")
        linha(f"AVISO: {rc.aviso_comercial}", tamanho=8, salto=12)
        linha("")

    if resultado.alertas:
        linha("Alertas", tamanho=12, salto=18)
        for alerta in resultado.alertas:
            linha(f"[{alerta.code}] {alerta.message}")
        linha("")

    if resultado.erros:
        linha("Erros/Bloqueios", tamanho=12, salto=18)
        for erro in resultado.erros:
            linha(f"[{erro.code}] {erro.message}")
        linha("")

    linha("Campo de validade", tamanho=12, salto=18)
    for chave, valor in resultado.parametros_validade.items():
        linha(f"{chave}: {valor}")

    pdf.save()
    return buffer.getvalue()
