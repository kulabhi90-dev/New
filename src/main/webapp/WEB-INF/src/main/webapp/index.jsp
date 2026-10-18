<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>View Personal Details</title>
    <style>
        * { box-sizing: border-box; }
        body { font-family: Arial, sans-serif; background: #f4f7f6; margin: 0; min-height: 100vh;
               display: flex; justify-content: center; align-items: center; padding: 16px; }
        .card { background: #fff; padding: 30px; border-radius: 8px; width: 100%; max-width: 460px;
                box-shadow: 0 4px 12px rgba(0,0,0,.1); }
        h2 { margin-top: 0; text-align: center; color: #222; }
        .alert { padding: 12px; margin-bottom: 20px; border-radius: 4px; font-size: 14px; display: none; }
        .alert.error { background: #fdecea; color: #8a1c1c; border: 1px solid #f5c6cb; display: block; }
        .alert.info  { background: #e8f1fb; color: #1f4e79; border: 1px solid #bcd6f1; display: block; }
        .field { margin-bottom: 15px; }
        label { display: block; font-weight: bold; margin-bottom: 5px; color: #333; }
        select, input { width: 100%; padding: 10px; border: 1px solid #ccc; border-radius: 4px; font-size: 15px; }
        select:focus, input:focus { outline: 2px solid #3498db; border-color: #3498db; }
        input[readonly] { background: #f0f2f2; color: #222; cursor: default; }
        .row { display: flex; gap: 8px; }
        .row select { flex: 1; }
        button { padding: 10px 14px; border: 0; border-radius: 4px; background: #3498db;
                 color: #fff; font-size: 14px; font-weight: bold; cursor: pointer; }
        button:hover { background: #2980b9; }
        button:disabled { background: #9bbfd8; cursor: not-allowed; }
        hr { border: 0; border-top: 1px solid #e3e6e6; margin: 20px 0; }
    </style>
</head>
<body>
<div class="card">
    <h2>View Personal Details</h2>

    <div id="message" class="alert" role="alert"></div>

    <div class="field">
        <label for="userSelect">Full Name</label>
        <div class="row">
            <select id="userSelect" disabled>
                <option value="">Loading...</option>
            </select>
            <button type="button" id="refreshBtn" title="Reload the list of names">Refresh</button>
        </div>
    </div>

    <hr>

    <div class="field">
        <label for="fullName">Full Name</label>
        <input type="text" id="fullName" readonly>
    </div>
    <div class="field">
        <label for="gender">Gender</label>
        <input type="text" id="gender" readonly>
    </div>
    <div class="field">
        <label for="emailAddress">Email Address</label>
        <input type="text" id="emailAddress" readonly>
    </div>
    <div class="field">
        <label for="city">City</label>
        <input type="text" id="city" readonly>
    </div>
    <div class="field">
        <label for="createdAt">Submitted On</label>
        <input type="text" id="createdAt" readonly>
    </div>
</div>

<script>
/* ============================================================
   CONFIGURATION  -  the only part you need to change
   ============================================================
   API_BASE : where your API lives.
              "/api"  -> same app / reverse proxy (no CORS needed)
              "https://<your-api-app>.azurewebsites.net/api" -> separate app
                         (your API must then allow CORS from this page's origin)

   LIST endpoint   GET  {API_BASE}/users
        -> JSON array, e.g. [{"id":1,"fullName":"Asha Rao"}, {"id":2,"fullName":"Ravi K"}]

   DETAIL endpoint GET  {API_BASE}/users/{id}
        -> JSON object, e.g.
           {"id":1,"fullName":"Asha Rao","gender":"Female",
            "emailAddress":"asha@x.com","city":"Pune","createdAt":"2026-10-16T05:44:54.029"}
   ============================================================ */
const API_BASE = "/api";
const LIST_URL   = () => API_BASE + "/users";
const DETAIL_URL = (id) => API_BASE + "/users/" + encodeURIComponent(id);

/* Property names accepted from your API (first match wins).
   Covers camelCase (fullName) and the DB column names (full_name). */
const KEYS = {
    id:           ["id", "Id", "ID"],
    fullName:     ["fullName", "full_name", "FullName", "name"],
    gender:       ["gender", "Gender"],
    emailAddress: ["emailAddress", "email_address", "EmailAddress", "email"],
    city:         ["city", "City"],
    createdAt:    ["createdAt", "created_at", "CreatedAt"]
};

/* ------------------------------------------------------------ */
const $ = (id) => document.getElementById(id);
const select = $("userSelect");
const FIELD_IDS = ["fullName", "gender", "emailAddress", "city", "createdAt"];

function pick(obj, names) {
    for (const n of names) {
        if (obj && obj[n] !== undefined && obj[n] !== null) return obj[n];
    }
    return "";
}

function showMessage(type, text) {
    const box = $("message");
    box.className = text ? "alert " + type : "alert";
    box.textContent = text || "";          // textContent => no HTML injection
}

function clearDetails() {
    FIELD_IDS.forEach((f) => { $(f).value = ""; });
}

function formatDate(value) {
    if (!value) return "";
    let s = String(value);
    // SQL Server DATETIME2 is stored in UTC; add 'Z' when the API sends no timezone.
    if (/^\d{4}-\d{2}-\d{2}T[\d:.]+$/.test(s)) s += "Z";
    const d = new Date(s);
    return isNaN(d.getTime()) ? String(value) : d.toLocaleString();
}

async function getJson(url) {
    const res = await fetch(url, { headers: { "Accept": "application/json" } });
    if (!res.ok) throw new Error("HTTP " + res.status + " from " + url);
    return res.json();
}

async function loadUsers() {
    showMessage("", "");
    clearDetails();
    select.disabled = true;
    select.innerHTML = "<option value=''>Loading...</option>";
    try {
        const users = await getJson(LIST_URL());
        if (!Array.isArray(users) || users.length === 0) {
            select.innerHTML = "<option value=''>No records found</option>";
            showMessage("info", "No records found yet.");
            return;
        }
        // Several people can share the same name, so the option VALUE is the id.
        select.innerHTML = "";
        const placeholder = new Option("-- Select a name --", "");
        select.add(placeholder);
        users.forEach((u) => {
            select.add(new Option(pick(u, KEYS.fullName), pick(u, KEYS.id)));
        });
        select.disabled = false;
    } catch (err) {
        console.error(err);
        select.innerHTML = "<option value=''>Could not load names</option>";
        showMessage("error", "Could not load the list of names. Please check the API and try again.");
    }
}

async function loadDetails(id) {
    clearDetails();
    showMessage("", "");
    if (!id) return;
    select.disabled = true;
    try {
        const u = await getJson(DETAIL_URL(id));
        $("fullName").value     = pick(u, KEYS.fullName);
        $("gender").value       = pick(u, KEYS.gender);
        $("emailAddress").value = pick(u, KEYS.emailAddress);
        $("city").value         = pick(u, KEYS.city);
        $("createdAt").value    = formatDate(pick(u, KEYS.createdAt));
    } catch (err) {
        console.error(err);
        showMessage("error", "Could not load the details for this person. Please try again.");
    } finally {
        select.disabled = false;
    }
}

select.addEventListener("change", () => loadDetails(select.value));
$("refreshBtn").addEventListener("click", loadUsers);
loadUsers();
</script>
</body>
</html>
