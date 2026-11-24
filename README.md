# HidroCare

Simulador de balanço hídrico para o curso de Enfermagem. Projeto Integrador do curso Técnico em Desenvolvimento de Sistemas (Senac Minas).

- Professor: cadastra cenários, vê as respostas dos estudantes e envia feedback.
- Estudante: responde os cenários publicados e lê o resultado e o feedback.

Tecnologias: Vue 3, Vite, Vue Router e Supabase (autenticação e banco PostgreSQL).

## Como rodar

Requisito: Node `^22.18.0` ou `>=24.12.0` (confira com `node -v`).

```bash
git clone https://github.com/HidroCare/hidrocare.git
cd hidrocare
npm ci
```

Crie o arquivo `.env.local` na raiz (ele NÃO vai para o GitHub) com os dados do projeto Supabase:

```
VITE_SUPABASE_URL=https://SEU-PROJETO.supabase.co
VITE_SUPABASE_ANON_KEY=SUA_CHAVE_ANON
```

Depois:

```bash
npm run dev      # abre em http://localhost:5173
npm run build    # gera a pasta dist
```

Nunca publique a chave `service_role` nem faça commit de `.env.local`.

## Banco de dados

Os scripts SQL estão em `database/`. Rode no SQL Editor do Supabase, na ordem numérica (01 a 08). Os de número 09 e 10 são opcionais.

## Login

- Professor: e-mail `pubXXXX@mg.senac.br`
- Estudante: e-mail `RA@senacminas.edu.br`

O perfil é definido pelo e-mail, no banco.

## Equipe

Alteir Lincoln, Kayky Augusto, Larissa Prado e Marco Antonio Barbosa.