// =========================================================
// SERVER.JS - API do "Guarda de Lentes" usando Supabase
// =========================================================
// Variaveis de ambiente necessarias (configure no servico onde
// for publicar - Render, Railway, etc.):
//   SUPABASE_URL          -> URL do seu projeto Supabase
//   SUPABASE_SERVICE_KEY  -> Service Role Key do Supabase
//   API_KEY               -> (opcional) senha simples da API
//   ALLOWED_ORIGIN        -> (opcional) trava o CORS
// =========================================================

const express = require('express');
const cors = require('cors');
const { createClient } = require('@supabase/supabase-js');

const app = express();
app.use(express.json({ limit: '5mb' }));

const ALLOWED_ORIGIN = process.env.ALLOWED_ORIGIN || '*';
app.use(cors({ origin: ALLOWED_ORIGIN }));

const supabase = createClient(
  process.env.SUPABASE_URL,
  process.env.SUPABASE_SERVICE_KEY
);

const API_KEY = process.env.API_KEY || '';

function verificarChave(req, res, next) {
  if (!API_KEY) return next();
  const auth = req.headers['authorization'] || '';
  const token = auth.startsWith('Bearer ') ? auth.slice(7) : '';
  if (token !== API_KEY) {
    return res.status(401).json({ erro: 'Chave de acesso invalida ou ausente.' });
  }
  next();
}
app.use(verificarChave);

function baseParaApi(row) {
  return {
    id: row.id,
    nome: row.nome,
    dataHora: row.data_hora,
    fmRows: row.fm_rows,
    cabecalho: row.cabecalho,
    rotulosColuna: row.rotulos_coluna,
    baseEntries: row.base_entries
  };
}

function historicoParaApi(row) {
  return {
    id: row.id,
    hora: row.hora,
    codigo: row.codigo,
    serial: row.serial,
    posicao: row.posicao,
    status: row.status,
    achou: row.achou
  };
}

app.get('/', (req, res) => {
  res.json({ ok: true, servico: 'Guarda de Lentes API', banco: 'Supabase' });
});

app.get('/bases', async (req, res) => {
  const { data, error } = await supabase
    .from('bases')
    .select('*')
    .order('id', { ascending: true });

  if (error) return res.status(500).json({ erro: error.message });
  res.json((data || []).map(baseParaApi));
});

app.post('/bases', async (req, res) => {
  const { nome, dataHora, fmRows, cabecalho, rotulosColuna, baseEntries } = req.body || {};
  if (!nome || !Array.isArray(fmRows) || !Array.isArray(baseEntries)) {
    return res.status(400).json({ erro: 'Campos obrigatorios: nome, fmRows, baseEntries.' });
  }

  const { data, error } = await supabase
    .from('bases')
    .insert([{
      nome,
      data_hora: dataHora || new Date().toLocaleString('pt-BR'),
      fm_rows: fmRows,
      cabecalho: cabecalho || {},
      rotulos_coluna: rotulosColuna || {},
      base_entries: baseEntries
    }])
    .select('id')
    .single();

  if (error) return res.status(500).json({ erro: error.message });
  res.json({ id: data.id });
});

app.get('/historico', async (req, res) => {
  const { data, error } = await supabase
    .from('historico')
    .select('*')
    .order('id', { ascending: true });

  if (error) return res.status(500).json({ erro: error.message });
  res.json((data || []).map(historicoParaApi));
});

app.post('/historico', async (req, res) => {
  const { hora, codigo, serial, posicao, status, achou } = req.body || {};

  const { data, error } = await supabase
    .from('historico')
    .insert([{ hora, codigo, serial, posicao, status, achou: !!achou }])
    .select('id')
    .single();

  if (error) return res.status(500).json({ erro: error.message });
  res.json({ id: data.id });
});

app.delete('/historico', async (req, res) => {
  const { error } = await supabase.from('historico').delete().gte('id', 0);
  if (error) return res.status(500).json({ erro: error.message });
  res.json({ ok: true });
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log('Guarda de Lentes API rodando na porta ' + PORT);
});
