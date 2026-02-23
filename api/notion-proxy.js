/**
 * Notion API 프록시 — 웹 브라우저 CORS 회피용.
 * 클라이언트는 이 엔드포인트로 path/method/body를 보내고,
 * 서버에서 api.notion.com으로 대신 요청해 응답을 그대로 반환합니다.
 */
const NOTION_BASE = 'https://api.notion.com/v1';

function corsHeaders(origin) {
  return {
    'Access-Control-Allow-Origin': origin || '*',
    'Access-Control-Allow-Methods': 'POST, GET, OPTIONS',
    'Access-Control-Allow-Headers': 'Authorization, Content-Type, Notion-Version',
  };
}

export default async function handler(req, res) {
  const origin = req.headers.origin || req.headers.referer?.replace(/\/$/, '') || '*';

  if (req.method === 'OPTIONS') {
    res.writeHead(204, corsHeaders(origin));
    return res.end();
  }

  if (req.method !== 'POST') {
    res.writeHead(405, { ...corsHeaders(origin), 'Content-Type': 'application/json' });
    return res.end(JSON.stringify({ error: 'Method not allowed' }));
  }

  const auth = req.headers.authorization;
  const notionVersion = req.headers['notion-version'] || '2022-06-28';

  if (!auth) {
    res.writeHead(401, { ...corsHeaders(origin), 'Content-Type': 'application/json' });
    return res.end(JSON.stringify({ error: 'Missing Authorization header' }));
  }

  let payload;
  try {
    payload = typeof req.body === 'string' ? JSON.parse(req.body) : req.body || {};
  } catch {
    res.writeHead(400, { ...corsHeaders(origin), 'Content-Type': 'application/json' });
    return res.end(JSON.stringify({ error: 'Invalid JSON body' }));
  }

  const { path, method = 'GET', body } = payload;
  if (!path || typeof path !== 'string') {
    res.writeHead(400, { ...corsHeaders(origin), 'Content-Type': 'application/json' });
    return res.end(JSON.stringify({ error: 'Missing or invalid path' }));
  }

  const normalizedPath = path.replace(/^\/+/, '');
  const url = `${NOTION_BASE}/${normalizedPath}`;

  const fetchOpts = {
    method: method.toUpperCase(),
    headers: {
      'Authorization': auth,
      'Notion-Version': notionVersion,
      'Content-Type': 'application/json',
    },
  };

  if (body != null && (fetchOpts.method === 'POST' || fetchOpts.method === 'PATCH')) {
    fetchOpts.body = JSON.stringify(body);
  }

  try {
    const notionRes = await fetch(url, fetchOpts);
    const text = await notionRes.text();
    const contentType = notionRes.headers.get('content-type') || 'application/json';

    res.writeHead(notionRes.status, {
      ...corsHeaders(origin),
      'Content-Type': contentType,
    });
    return res.end(text);
  } catch (err) {
    res.writeHead(502, { ...corsHeaders(origin), 'Content-Type': 'application/json' });
    return res.end(JSON.stringify({ error: 'Notion request failed', message: err.message }));
  }
}
