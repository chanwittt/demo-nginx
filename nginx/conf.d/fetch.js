async function getProfile(r) {
    ngx
      .fetch("http://api-svc.f5poc.svc.cluster.local/userinfo/"+ r.variables.uri_suffix, {
        headers: {
          "User-Agent": "Nginx",
          "Authorization": r.headersIn.authorization
        },
      })
      .then((res) => res.json())
      .then((response) => {
        // const titles = response.map((article) => article.title);
        r.headersOut["Content-Type"] = "application/json";
        r.headersOut["Authorization"] = r.headersIn.authorization;
        r.headersOut["uid"] = response.uid;
        r.headersOut["name"] = response.name;
        r.headersOut["email"] = response.email;
        r.status = 200;
        r.sendHeader();
        r.send(JSON.stringify(response));
        r.finish();
        // r.return(200, JSON.stringify(response));
      })
      .catch((error) => {
        r.log(error);
      });
  }
  
  // don't forget to export functions
  export default { getProfile };