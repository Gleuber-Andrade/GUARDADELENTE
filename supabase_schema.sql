-- =========================================================
-- Rode este script no Supabase: Project > SQL Editor > New query
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
  created_at timestamptz not null default now()
);

alter table bases enable row level security;
alter table historico enable row level security;
