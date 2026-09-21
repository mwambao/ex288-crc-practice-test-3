const http=require('http'); http.createServer((q,r)=>{r.end(`${process.env.MESSAGE||'unset'}|${process.env.API_USER||'unset'}\n`)}).listen(8080,'0.0.0.0');
