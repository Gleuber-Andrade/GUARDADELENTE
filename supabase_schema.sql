// =========================================================
// Edge Function "api" - Roda no Supabase
// =========================================================
// Variáveis de ambiente (definir no Supabase):
//   SUPABASE_URL              -> já fornecida automaticamente
//   SUPABASE_SERVICE_ROLE_KEY -> já fornecida automaticamente
//   API_KEY                   -> opcional (definir com: supabase secrets set API_KEY=minha-senha)
// =========================================================

import { serve } from "https://deno.land/std@0.192.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.45.0";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
const API_KEY = Deno.env.get("API_KEY") || "";

const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);

function corsHeaders() {
  return {
    "Access-Control-Allow-Origin": "*",
    "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
    "Access-Control-Allow-Methods": "GET, POST, DELETE, OPTIONS",
  };
}

function jsonResponse(body: unknown, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders(), "Content-Type": "application/json" },
  });
}

function baseParaApi(row: any) {
  return {
    id: row.id,
    nome: row.nome,
    dataHora: row.data_hora,
    fmRows: row.fm_rows,
    cabecalho: row.cabecalho,
    rotulosColuna: row.rotulos_coluna,
    baseEntries: row.base_entries,
  };
}

function historicoParaApi(row: any) {
  return {
    id: row.id,
    hora: row.hora,
    codigo: row.codigo,
    serial: row.serial,
    posicao: row.posicao,
    status: row.status,
    achou: row.achou,
    ts: row.ts,
  };
}

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders() });
  }

  // Autenticação simples com API_KEY (opcional)
  if (API_KEY) {
    const auth = req.headers.get("authorization") || "";
    const token = auth.startsWith("Bearer ") ? auth.slice(7) : "";
    if (token !== API_KEY) {
      return jsonResponse({ erro: "Chave de acesso inválida ou ausente." }, 401);
    }
  }

  const url = new URL(req.url);
  const path = url.pathname.replace(/^\/functions\/v1\/[^/]+/, "") || "/";
  const parts = path.split("/").filter(Boolean);

  try {
    // Health check
    if (parts.length === 0 && req.method === "GET") {
      return jsonResponse({ ok: true, servico: "Guarda de Lentes API", banco: "Supabase" });
    }

    // ---- /bases ----
    if (parts[0] === "bases") {
      // GET /bases
      if (parts.length === 1 && req.method === "GET") {
        const { data, error } = await supabase
          .from("bases")
          .select("*")
          .order("id", { ascending: true });
        if (error) return jsonResponse({ erro: error.message }, 500);
        return jsonResponse((data || []).map(baseParaApi));
      }

      // POST /bases
      if (parts.length === 1 && req.method === "POST") {
        const body = await req.json();
        const { nome, dataHora, fmRows, cabecalho, rotulosColuna, baseEntries } = body || {};
        if (!nome || !Array.isArray(fmRows) || !Array.isArray(baseEntries)) {
          return jsonResponse({ erro: "Campos obrigatórios: nome, fmRows, baseEntries." }, 400);
        }
        const { data, error } = await supabase
          .from("bases")
          .insert([{
            nome,
            data_hora: dataHora || new Date().toLocaleString("pt-BR"),
            fm_rows: fmRows,
            cabecalho: cabecalho || {},
            rotulos_coluna: rotulosColuna || {},
            base_entries: baseEntries,
          }])
          .select("id")
          .single();
        if (error) return jsonResponse({ erro: error.message }, 500);
        return jsonResponse({ id: data.id });
      }

      // DELETE /bases/:id
      if (parts.length === 2 && req.method === "DELETE") {
        const id = parts[1];
        const { error } = await supabase.from("bases").delete().eq("id", id);
        if (error) return jsonResponse({ erro: error.message }, 500);
        return jsonResponse({ ok: true });
      }
    }

    // ---- /historico ----
    if (parts[0] === "historico") {
      // GET /historico
      if (parts.length === 1 && req.method === "GET") {
        const { data, error } = await supabase
          .from("historico")
          .select("*")
          .order("id", { ascending: true });
        if (error) return jsonResponse({ erro: error.message }, 500);
        return jsonResponse((data || []).map(historicoParaApi));
      }

      // POST /historico
      if (parts.length === 1 && req.method === "POST") {
        const body = await req.json();
        const { hora, codigo, serial, posicao, status, achou, ts } = body || {};
        const { data, error } = await supabase
          .from("historico")
          .insert([{ hora, codigo, serial, posicao, status, achou: !!achou, ts: ts || Date.now() }])
          .select("id")
          .single();
        if (error) return jsonResponse({ erro: error.message }, 500);
        return jsonResponse({ id: data.id });
      }

      // DELETE /historico
      if (parts.length === 1 && req.method === "DELETE") {
        const { error } = await supabase.from("historico").delete().gte("id", 0);
        if (error) return jsonResponse({ erro: error.message }, 500);
        return jsonResponse({ ok: true });
      }
    }

    return jsonResponse({ erro: "Rota não encontrada: " + path }, 404);
  } catch (err) {
    return jsonResponse({ erro: String(err) }, 500);
  }
});
