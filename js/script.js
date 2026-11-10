
document.addEventListener("DOMContentLoaded", () => {
    // 1. Elementos HTML
    const tabela = document.querySelector(".tabela-dados tbody");

    const tipo = document.getElementById("tipo");
    const horario = document.getElementById("horario");
    const descricao = document.getElementById("descricao");
    const valor = document.getElementById("valor");

    const btnAdicionar = document.getElementById("btnAdicionar");
    const btnSubmeter = document.getElementById("btnSubmeter");

    const alerta = document.querySelector(".alerta-validacao");

    const totalEntradasHTML = document.getElementById("totalEntradas");
    const totalSaidasHTML = document.getElementById("totalSaidas");
    const balancoHTML = document.getElementById("balanco");

    // Verifica se os elementos necessários existem
    if (!tabela || !tipo || !horario || !descricao ||
        !valor || !btnAdicionar || !alerta) {
        console.error("Erro: algum elemento HTML não foi encontrado.");
        return;
    }

    // 2. Exibir mensagens
    function mostrarAlerta(mensagem) {
        alerta.textContent = mensagem;
        alerta.style.display = "block";
    }

    function esconderAlerta() {
        alerta.style.display = "none";
    }

    // 3. Validar campos
    function validarCampos() {
        const quantidade = valor.valueAsNumber;

        if ( !tipo.value || !horario.value || !descricao.value.trim() || !valor.value.trim() ) {
            mostrarAlerta("Preencha todos os campos!");
            return false;
        }

        if (!Number.isFinite(quantidade) || quantidade <= 0) {
            mostrarAlerta("Informe um valor positivo em mL!");
            return false;
        }

        esconderAlerta();
        return true;
    }

    // 4. Adicionar registro
    function adicionarRegistro() {

        if (!validarCampos()) {
            return;
        }

        const tipoValor = tipo.value;
        const horarioValor = horario.value;
        const descricaoValor = descricao.value.trim();
        const valorNumerico = valor.valueAsNumber;

        const novaLinha = document.createElement("tr");

        novaLinha.dataset.tipo = tipoValor;
        novaLinha.dataset.valor = valorNumerico;

        // Tipo
        const tdTipo = document.createElement("td");
        const badge = document.createElement("span");

        badge.classList.add("badge", tipoValor);
        badge.textContent = tipoValor === "entrada" ? "Entrada" : "Saída";

        tdTipo.appendChild(badge);

        // Horário
        const tdHorario = document.createElement("td");
        tdHorario.textContent = horarioValor;

        // Descrição
        const tdDescricao = document.createElement("td");
        tdDescricao.textContent = descricaoValor;

        // Valor
        const tdValor = document.createElement("td");
        tdValor.textContent = valorNumerico;

        // Botão remover
        const tdAcao = document.createElement("td");
        const btnRemover = document.createElement("button");

        btnRemover.type = "button";
        btnRemover.classList.add("btn-tabela", "remover");
        btnRemover.textContent = "Remover";

        tdAcao.appendChild(btnRemover);

        // Montagem da linha
        novaLinha.append(
            tdTipo,
            tdHorario,
            tdDescricao,
            tdValor,
            tdAcao
        );

        // Inserção na tabela
        const linhaFormulario = document.getElementById("linha-formulario");

        if (linhaFormulario) {
            tabela.insertBefore(novaLinha, linhaFormulario);
        } else {
            tabela.appendChild(novaLinha);
        }

        // Limpar campos
        tipo.value = "";
        horario.value = "";
        descricao.value = "";
        valor.value = "";

        calcularBalanco();
        esconderAlerta();
    }

    // 5. Remover registro
    function removerRegistro(event) {
        const botao = event.target.closest(".remover");

        if (!botao) return;

        botao.closest("tr").remove();
        calcularBalanco();
    }

    // 6. Calcular balanço hídrico
    function calcularBalanco() {

        let entradas = 0;
        let saidas = 0;

        const registros = tabela.querySelectorAll("tr[data-tipo]");

        registros.forEach(registro => {
            const quantidade = Number(registro.dataset.valor);

            if (registro.dataset.tipo === "entrada") {
                entradas += quantidade;
            } else if (registro.dataset.tipo === "saida") {
                saidas += quantidade;
            }
        });

        const resultado = entradas - saidas;

        totalEntradasHTML.textContent = `${entradas} mL`;
        totalSaidasHTML.textContent = `${saidas} mL`;

        balancoHTML.textContent = `${resultado > 0 ? "+" : ""}${resultado} mL`;
    }

    // 7. Submeter registros
    function submeterRegistros() {

        if (tabela.querySelectorAll("tr[data-tipo]").length === 0) {
            mostrarAlerta("Adicione pelo menos um registro!");
            return;
        }

        // Impede submissão se os campos de um novo registro
        // estiverem parcialmente preenchidos.
        const camposPreenchidos =
            tipo.value !== "" ||
            horario.value !== "" ||
            descricao.value.trim() !== "" ||
            valor.value.trim() !== "";

        if (camposPreenchidos) {
            mostrarAlerta("Finalize ou limpe o registro antes de submeter!");
            return;
        }

        esconderAlerta();
        calcularBalanco();

        alert("Registros submetidos com sucesso!");
    }

    // 8. Eventos
    btnAdicionar.addEventListener("click", adicionarRegistro);
    tabela.addEventListener("click", removerRegistro);

    if (btnSubmeter) {
        btnSubmeter.addEventListener("click", submeterRegistros);
    }

    // Cálculo inicial
    calcularBalanco();
});
