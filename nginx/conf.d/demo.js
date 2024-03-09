async function join_subrequests(r) {
    const subs = ["/myapi/products", "/myapi/shoping-cart/"+r.variables.uri_suffix, "/myapi/users/"+r.variables.uri_suffix, "/myapi/marketing-promos"]
    let results = await Promise.all(subs.map(uri => r.subrequest(uri)));

    let response = results.map(reply => ({
        uri: reply.uri,
        // code: reply.status,
        body: reply.responseText,
    }));
    r.return(200, JSON.stringify(response));
}

export default { join_subrequests }