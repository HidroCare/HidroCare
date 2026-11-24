-- =====================================================================
-- HidroCare · 02 · Ajustes nas tabelas
-- Rodar DEPOIS do 01. Pode ser rodado de novo sem problema.
--
-- Antes de rodar, confira os dados de teste (veja a rotina, passo 0):
--   * valores de "tipo" nas tabelas registros e gabarito_itens
--   * pares repetidos em submissoes (mesmo estudante + mesmo cenário)
-- =====================================================================

-- 2.1 Padronizar o "tipo" já gravado (entrada | saida, sem acento) ------
update public.registros       set tipo = 'saida'   where lower(tipo) in ('saída', 'saida');
update public.registros       set tipo = 'entrada' where lower(tipo) = 'entrada';
update public.gabarito_itens  set tipo = 'saida'   where lower(tipo) in ('saída', 'saida');
update public.gabarito_itens  set tipo = 'entrada' where lower(tipo) = 'entrada';

-- 2.2 Colunas que faltavam -----------------------------------------------
-- Período de observação do cenário: sem ele, o balanço não se interpreta.
alter table public.cenarios  add column if not exists periodo_horas integer not null default 24;
-- Horário que o estudante informa em cada registro (o gabarito já tem o seu).
alter table public.registros add column if not exists horario time;

-- 2.3 Valores padrão: id e datas não dependem mais de quem insere --------
alter table public.pacientes       alter column id set default gen_random_uuid();
alter table public.cenarios        alter column id set default gen_random_uuid();
alter table public.gabarito_itens  alter column id set default gen_random_uuid();
alter table public.submissoes      alter column id set default gen_random_uuid();
alter table public.registros       alter column id set default gen_random_uuid();
alter table public.resultados      alter column id set default gen_random_uuid();
alter table public.feedbacks       alter column id set default gen_random_uuid();

alter table public.pacientes       alter column created_at set default now();
alter table public.cenarios        alter column created_at set default now();
alter table public.gabarito_itens  alter column created_at set default now();
alter table public.submissoes      alter column created_at set default now();
alter table public.registros       alter column created_at set default now();
alter table public.resultados      alter column created_at set default now();
alter table public.usuarios        alter column created_at set default now();
alter table public.feedbacks       alter column criado_em  set default now();

alter table public.cenarios    alter column publicado   set default false;  -- nasce como rascunho
alter table public.submissoes  alter column enviada_em  set default now();
alter table public.submissoes  alter column bloqueada   set default true;   -- RN05: enviou, bloqueou
alter table public.registros   alter column correto     set default false;  -- ainda não corrigido

-- 2.4 Restrições: o banco recusa dado inválido, mesmo que a tela falhe ---
-- Envio único (RN05): um estudante, um envio por cenário.
alter table public.submissoes drop constraint if exists submissoes_unica_por_estudante;
alter table public.submissoes add  constraint submissoes_unica_por_estudante unique (cenario_id, estudante_id);

-- Um resultado por submissão.
alter table public.resultados drop constraint if exists resultados_uma_por_submissao;
alter table public.resultados add  constraint resultados_uma_por_submissao unique (submissao_id);

-- "not valid" = vale para as linhas NOVAS; não reclama de dado de teste antigo.
-- (Quando limparem os dados de teste: alter table ... validate constraint nome;)
alter table public.registros drop constraint if exists registros_tipo_valido;
alter table public.registros add  constraint registros_tipo_valido check (tipo in ('entrada', 'saida')) not valid;

alter table public.gabarito_itens drop constraint if exists gabarito_tipo_valido;
alter table public.gabarito_itens add  constraint gabarito_tipo_valido check (tipo in ('entrada', 'saida')) not valid;

alter table public.registros drop constraint if exists registros_valor_positivo;
alter table public.registros add  constraint registros_valor_positivo check (valor_ml > 0) not valid;

alter table public.gabarito_itens drop constraint if exists gabarito_valor_positivo;
alter table public.gabarito_itens add  constraint gabarito_valor_positivo check (valor_ml > 0) not valid;

alter table public.resultados drop constraint if exists resultados_classificacao_valida;
alter table public.resultados add  constraint resultados_classificacao_valida check (classificacao in ('positivo', 'neutro', 'negativo')) not valid;

alter table public.resultados drop constraint if exists resultados_contagens_validas;
alter table public.resultados add  constraint resultados_contagens_validas check (acertos >= 0 and erros >= 0) not valid;

alter table public.cenarios drop constraint if exists cenarios_periodo_positivo;
alter table public.cenarios add  constraint cenarios_periodo_positivo check (periodo_horas > 0) not valid;
