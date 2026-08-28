-- =========================================================
-- Rode este script no Supabase: Project > SQL Editor > New query
-- Se as tabelas já existem (de uma configuração anterior), este
-- script só adiciona a coluna nova "ts" que faltava — pode rodar
-- sem medo, ele não apaga nada.
-- =========================================================

create table if not exists bases (
  id bigint generated always as identity primary key,
  nome text not null,
  data_hora text,
  fm_rows jsonb not null default '[]',
  cabecalho jsonb not null default '{}',
  rotulos_coluna jsonb not null default '{}',
  base_entries jsonb not null default '[]',
  created_at timestamptz not null default now()
);

create table if not exists historico (
  id bigint generated always as identity primary key,
  hora text,
  codigo text,
  serial text,
  posicao text,
  status text,
  achou boolean default false,
  ts bigint,
  created_at timestamptz not null default now()
);

-- Garante a coluna "ts" mesmo se a tabela historico já existia de antes
-- (usada pelo botão "Zerar Contadores" para não reaparecer leituras
-- antigas depois de atualizar a página).
alter table historico add column if not exists ts bigint;

-- Como a Edge Function usa a Service Role Key (que já ignora RLS),
-- não é obrigatório mexer em Row Level Security. Se quiser deixar as
-- tabelas travadas por padrão mesmo assim (mais seguro caso a anon key
-- vaze), habilite o RLS sem criar nenhuma política — isso bloqueia
-- qualquer acesso que não seja via Service Role Key:
alter table bases enable row level security;
alter table historico enable row level security;
