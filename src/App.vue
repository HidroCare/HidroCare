<template>
  <!-- O router-view injeta dinamicamente a tela atual com base na URL (ex: /login, /escolha-cenario, /atividade) -->
  <router-view />
</template>

<script setup>
// Nenhuma lógica complexa é necessária aqui no App.vue para este MVP, 
// pois o controle de autenticação e navegação fica por conta das rotas e dos componentes específicos.
</script>

<style>
/* Reset global e importação do arquivo de estilos unificado */
* {
  margin: 0;
  padding: 0;
  box-sizing: border-box;
  font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
}

body {
  background-color: #f4f6f9;
  min-height: 100vh;
}
</style>