const BASE=process.env.NEXT_PUBLIC_API_URL||'http://localhost:4000/api';
export async function api(path,options={}){const res=await fetch(`${BASE}${path}`,{...options,headers:{'Content-Type':'application/json',...(options.headers||{})},cache:'no-store'});const data=await res.json().catch(()=>({}));if(!res.ok)throw new Error(data.error||'No se pudo completar la solicitud');return data}
