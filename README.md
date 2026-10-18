# D6 - View Personal Details (front-end only)

Static page (src/main/webapp/index.html) packaged as ROOT.war for Tomcat 10.1 / Java 17,
same build + deploy flow as D5.

Set API_BASE at the top of the <script> in index.html, then build your API to match:

GET {API_BASE}/users        -> [{"id":1,"fullName":"Asha Rao"}, ...]
GET {API_BASE}/users/{id}   -> {"id":1,"fullName":"...","gender":"...","emailAddress":"...","city":"...","createdAt":"..."}

If the API is hosted on a different origin, enable CORS for this page's origin.
In azure-pipelines.yml set webAppName to a NEW App Service (not the D5 one).
