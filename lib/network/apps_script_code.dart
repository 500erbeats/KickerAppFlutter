/// Der komplette Google-Apps-Script-Code als Rohstring, identisch zu dem der nativen
/// iOS-/Android-Apps. Alle Apps sprechen mit demselben Backend.
const String appsScriptSource = r'''function doGet(e) {
  var sheet = getSheet_();
  var action = e.parameter.action;

  if (action === "status") {
    return jsonResponse_({ ids: idsInSheet_(sheet) });
  }

  if (action === "rows") {
    return jsonResponse_({ rows: fullRows_(sheet) });
  }

  if (action === "players") {
    return jsonResponse_({ players: getPlayers_() });
  }

  if (action === "view") {
    return HtmlService.createHtmlOutput(tablesHtml_(ScriptApp.getService().getUrl())).setTitle("Kicker-Tabellen");
  }

  // Kein Parameter -> Browser-Aufruf durch einen Kollegen: einfaches Formular zeigen.
  // Die echte /exec-URL wird fest ins Formular eingebettet (siehe formHtml_), weil
  // window.location.href im Browser manchmal auf eine andere Inhalts-URL zeigt.
  return HtmlService.createHtmlOutput(formHtml_(ScriptApp.getService().getUrl(), getPlayers_())).setTitle("Kicker-Ergebnis eintragen");
}

function doPost(e) {
  var action = e.parameter.action;

  if (action === "players") {
    var data = JSON.parse(e.postData.contents);
    setPlayers_(data.players || []);
    return jsonResponse_({ status: "ok" });
  }

  var sheet = getSheet_();
  var data = JSON.parse(e.postData.contents);
  upsertRow_(sheet, data);
  return jsonResponse_({ status: "ok" });
}

function getPlayersSheet_() {
  var ss = SpreadsheetApp.getActiveSpreadsheet();
  return ss.getSheetByName("Spieler") || ss.insertSheet("Spieler");
}

function getPlayers_() {
  var sheet = getPlayersSheet_();
  var values = sheet.getDataRange().getValues();
  var players = [];
  for (var i = 0; i < values.length; i++) {
    if (values[i][0]) players.push(values[i][0]);
  }
  return players;
}

function setPlayers_(players) {
  var sheet = getPlayersSheet_();
  sheet.clear();
  if (players.length > 0) {
    sheet.getRange(1, 1, players.length, 1).setValues(players.map(function (p) { return [p]; }));
  }
}

function escapeHtml_(text) {
  return String(text)
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;")
    .replace(/"/g, "&quot;");
}

function getSheet_() {
  var ss = SpreadsheetApp.getActiveSpreadsheet();
  return ss.getSheetByName("Ergebnisse") || ss.insertSheet("Ergebnisse");
}

function ensureHeader_(sheet) {
  if (sheet.getLastRow() === 0) {
    sheet.appendRow(["ID", "Datum", "Modus", "Wandseite", "Treppenseite", "ToreWand", "ToreTreppe", "Eigentore"]);
  }
}

function jsonResponse_(obj) {
  return ContentService.createTextOutput(JSON.stringify(obj)).setMimeType(ContentService.MimeType.JSON);
}

function idsInSheet_(sheet) {
  ensureHeader_(sheet);
  var rows = sheet.getDataRange().getValues();
  var ids = [];
  for (var i = 1; i < rows.length; i++) {
    if (rows[i][0]) ids.push(rows[i][0]);
  }
  return ids;
}

function fullRows_(sheet) {
  ensureHeader_(sheet);
  var values = sheet.getDataRange().getValues();
  var result = [];

  for (var i = 1; i < values.length; i++) {
    var row = values[i];
    // Manuell direkt ins Sheet eingetragene Zeile ohne ID -> ID nachträglich vergeben,
    // damit sie beim nächsten Abgleich stabil bleibt und nicht doppelt importiert wird.
    if (!row[0]) {
      row[0] = Utilities.getUuid();
      sheet.getRange(i + 1, 1).setValue(row[0]);
    }
    result.push({
      id: row[0],
      date: row[1] instanceof Date ? row[1].toISOString() : String(row[1]),
      mode: row[2],
      wandPlayers: row[3],
      treppePlayers: row[4],
      scoreWand: row[5],
      scoreTreppe: row[6],
      ownGoals: row[7]
    });
  }
  return result;
}

function upsertRow_(sheet, data) {
  ensureHeader_(sheet);
  var rows = sheet.getDataRange().getValues();
  var rowIndex = -1;
  for (var i = 1; i < rows.length; i++) {
    if (rows[i][0] === data.id) { rowIndex = i + 1; break; }
  }

  if (data.deleted) {
    if (rowIndex > 0) sheet.deleteRow(rowIndex);
    return;
  }

  var rowValues = [data.id, data.date, data.mode, data.wandPlayers, data.treppePlayers, data.scoreWand, data.scoreTreppe, data.ownGoals];
  var targetRow = rowIndex > 0 ? rowIndex : sheet.getLastRow() + 1;

  // Datum-Spalte (B) VOR dem Schreiben als Text formatieren, damit Google Sheets das
  // ISO-Datum nicht eigenmächtig in ein Datumsobjekt umwandelt.
  sheet.getRange(targetRow, 2).setNumberFormat("@");

  sheet.getRange(targetRow, 1, 1, rowValues.length).setValues([rowValues]);
}

function formHtml_(scriptUrl, players) {
  var optionNames = players.slice();
  if (optionNames.indexOf("Reserve") === -1) optionNames.push("Reserve");

  var optionsHtml = optionNames.map(function (p) {
    return '<option value="' + escapeHtml_(p) + '">' + escapeHtml_(p) + '</option>';
  }).join('');
  optionsHtml += '<option value="__custom__">Anderer Name…</option>';

  var slot = function (id, label) {
    return '<label>' + label + '</label>' +
      '<select id="' + id + '" onchange="onSlotChange(\'' + id + '\')">' + optionsHtml + '</select>' +
      '<input id="' + id + 'Custom" placeholder="Name eingeben" style="display:none;margin-top:4px" oninput="refreshOptionAvailability()">';
  };

  return '<!DOCTYPE html><html><head><meta name="viewport" content="width=device-width, initial-scale=1">' +
    '<style>body{font-family:-apple-system,sans-serif;padding:16px;max-width:420px;margin:auto}' +
    'label{display:block;margin-top:12px;font-weight:600}' +
    'input,select{width:100%;padding:8px;margin-top:4px;box-sizing:border-box;font-size:16px}' +
    'button{width:100%;margin-top:20px;padding:12px;background:#2e7d32;color:white;border:none;border-radius:8px;font-size:16px}' +
    '.twoOnly{display:none}' +
    '#status{margin-top:12px;text-align:center;font-weight:600}</style></head><body>' +
    '<h2>⚽ Kicker-Ergebnis eintragen</h2>' +
    '<label>Modus</label><select id="mode" onchange="toggleMode()"><option value="1vs1">1 vs 1</option><option value="2vs2">2 vs 2</option></select>' +
    slot('wand1', 'Wandseite – Spieler 1') +
    '<div class="twoOnly">' + slot('wand2', 'Wandseite – Spieler 2') + '</div>' +
    slot('treppe1', 'Treppenseite – Spieler 1') +
    '<div class="twoOnly">' + slot('treppe2', 'Treppenseite – Spieler 2') + '</div>' +
    '<label>Tore Wandseite</label><input id="scoreWand" type="number" value="0">' +
    '<label>Tore Treppenseite</label><input id="scoreTreppe" type="number" value="0">' +
    '<label>Eigentore (optional, Format "Name:Anzahl, Name:Anzahl")</label><input id="ownGoals" placeholder="z.B. Peter:1">' +
    '<button onclick="submitResult()">Speichern</button>' +
    '<div id="status"></div>' +
    '<script>' +
    'var SCRIPT_URL = "' + scriptUrl + '";' +
    'var SLOT_IDS = ["wand1","wand2","treppe1","treppe2"];' +
    'function uuid(){return "xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx".replace(/[xy]/g,function(c){var r=Math.random()*16|0,v=c=="x"?r:(r&0x3|0x8);return v.toString(16);});}' +
    'function isSlotVisible(id){' +
    'if(id==="wand2"||id==="treppe2"){return document.getElementById("mode").value==="2vs2";}' +
    'return true;' +
    '}' +
    'function toggleMode(){' +
    'var is2v2=document.getElementById("mode").value==="2vs2";' +
    'document.querySelectorAll(".twoOnly").forEach(function(el){el.style.display=is2v2?"block":"none";});' +
    'refreshOptionAvailability();' +
    '}' +
    'function toggleCustom(slotId){' +
    'var select=document.getElementById(slotId);' +
    'var custom=document.getElementById(slotId+"Custom");' +
    'custom.style.display=select.value==="__custom__"?"block":"none";' +
    '}' +
    'function onSlotChange(slotId){' +
    'toggleCustom(slotId);' +
    'refreshOptionAvailability();' +
    '}' +
    'function slotValue(slotId){' +
    'var select=document.getElementById(slotId);' +
    'if(select.value==="__custom__"){return document.getElementById(slotId+"Custom").value.trim();}' +
    'return select.value;' +
    '}' +
    'function refreshOptionAvailability(){' +
    'SLOT_IDS.forEach(function(id){' +
    'var select=document.getElementById(id);' +
    'var others=[];' +
    'SLOT_IDS.forEach(function(otherId){' +
    'if(otherId===id||!isSlotVisible(otherId))return;' +
    'var val=slotValue(otherId);' +
    'if(val)others.push(val);' +
    '});' +
    'Array.prototype.forEach.call(select.options,function(opt){' +
    'if(opt.value==="__custom__"){opt.disabled=false;return;}' +
    'opt.disabled=others.indexOf(opt.value)!==-1;' +
    '});' +
    '});' +
    '}' +
    'function submitResult(){' +
    'var mode=document.getElementById("mode").value;' +
    'var wand1=slotValue("wand1");var treppe1=slotValue("treppe1");' +
    'var wandPlayers=wand1;var treppePlayers=treppe1;' +
    'var allNames=[wand1,treppe1];' +
    'if(mode==="2vs2"){' +
    'var wand2=slotValue("wand2");var treppe2=slotValue("treppe2");' +
    'wandPlayers+=" & "+wand2;treppePlayers+=" & "+treppe2;' +
    'allNames.push(wand2,treppe2);' +
    '}' +
    'var nonEmpty=allNames.filter(function(n){return n;});' +
    'var hasDuplicate=nonEmpty.some(function(n,i){return nonEmpty.indexOf(n)!==i;});' +
    'if(hasDuplicate){' +
    'document.getElementById("status").textContent="⚠️ Ein Name ist mehrfach ausgewählt.";' +
    'return;' +
    '}' +
    'var payload={id:uuid(),date:new Date().toISOString(),mode:mode,' +
    'wandPlayers:wandPlayers,treppePlayers:treppePlayers,' +
    'scoreWand:parseInt(document.getElementById("scoreWand").value)||0,scoreTreppe:parseInt(document.getElementById("scoreTreppe").value)||0,' +
    'ownGoals:document.getElementById("ownGoals").value,deleted:false};' +
    'document.getElementById("status").textContent="Speichere...";' +
    'fetch(SCRIPT_URL,{method:"POST",body:JSON.stringify(payload)})' +
    '.then(function(){document.getElementById("status").textContent="✅ Gespeichert!";resetForm();})' +
    '.catch(function(){document.getElementById("status").textContent="⚠️ Fehler beim Speichern.";});' +
    '}' +
    'function resetForm(){' +
    'document.getElementById("mode").value="1vs1";toggleMode();' +
    'SLOT_IDS.forEach(function(id){' +
    'var select=document.getElementById(id);' +
    'select.selectedIndex=0;' +
    'document.getElementById(id+"Custom").value="";' +
    'document.getElementById(id+"Custom").style.display="none";' +
    '});' +
    'document.getElementById("scoreWand").value="0";' +
    'document.getElementById("scoreTreppe").value="0";' +
    'document.getElementById("ownGoals").value="";' +
    'refreshOptionAvailability();' +
    '}' +
    'refreshOptionAvailability();' +
    '</script></body></html>';
}

function tablesHtml_(scriptUrl) {
  return '<!DOCTYPE html><html><head><meta name="viewport" content="width=device-width, initial-scale=1">' +
    '<style>' +
    'body{font-family:-apple-system,sans-serif;padding:16px;max-width:480px;margin:auto;background:#f5f5f5}' +
    'h2{margin:0 0 16px}' +
    '.period-row{display:flex;align-items:center;justify-content:space-between;margin-bottom:12px;background:white;padding:8px 12px;border-radius:10px}' +
    '.period-row button{background:none;border:none;font-size:22px;cursor:pointer;padding:4px 12px;color:#2e7d32}' +
    '.period-row button:disabled{color:#ccc}' +
    '.period-mid{text-align:center}' +
    '#periodLabel{font-weight:600;margin-bottom:4px}' +
    'select{padding:6px;border-radius:6px;border:1px solid #ccc}' +
    '.tabs{display:flex;gap:8px;margin-bottom:12px}' +
    '.tab{flex:1;padding:10px;text-align:center;border-radius:8px;background:#e0e0e0;cursor:pointer;font-size:14px}' +
    '.tab.active{background:#2e7d32;color:white}' +
    'table{width:100%;border-collapse:collapse;background:white;border-radius:10px;overflow:hidden}' +
    'th,td{padding:10px;font-size:14px;border-bottom:1px solid #eee}' +
    'th{background:#2e7d32;color:white;text-align:left}' +
    'td:nth-child(2),td:nth-child(3),th:nth-child(2),th:nth-child(3){text-align:right}' +
    '#empty{text-align:center;color:#999;padding:24px;background:white;border-radius:10px}' +
    '</style></head><body>' +
    '<h2>🏆 Kicker-Tabellen</h2>' +
    '<a href="' + scriptUrl + '" style="display:inline-block;margin-bottom:12px;padding:8px 14px;background:#2e7d32;color:white;text-decoration:none;border-radius:8px;font-size:14px">+ Neues Ergebnis</a>' +
    '<div class="period-row" id="periodRow">' +
    '<button onclick="shiftPeriod(-1)">‹</button>' +
    '<div class="period-mid">' +
    '<div id="periodLabel">…</div>' +
    '<select id="periodType" onchange="onPeriodTypeChange()">' +
    '<option value="month">Monat</option><option value="quarter" selected>Quartal</option>' +
    '<option value="halfyear">Halbjahr</option><option value="year">Jahr</option>' +
    '</select>' +
    '</div>' +
    '<button onclick="shiftPeriod(1)" id="nextBtn">›</button>' +
    '</div>' +
    '<div class="tabs">' +
    '<div class="tab active" id="tab0" onclick="selectTab(0)">1 vs 1</div>' +
    '<div class="tab" id="tab1" onclick="selectTab(1)">2 vs 2</div>' +
    '<div class="tab" id="tab2" onclick="selectTab(2)">Eigentore</div>' +
    '<div class="tab" id="tab3" onclick="selectTab(3)">Verlauf</div>' +
    '</div>' +
    '<div id="content">Lade…</div>' +
    '<script>' +
    'var SCRIPT_URL = "' + scriptUrl + '";' +
    'var allRows = [];' +
    'var periodOffset = 0;' +
    'var selectedTab = 0;' +

    'function periodBounds(year, startMonth1, spanMonths) {' +
    'var start = new Date(year, startMonth1 - 1, 1, 0, 0, 0);' +
    'var end = new Date(year, startMonth1 - 1 + spanMonths, 0, 23, 59, 59);' +
    'return { start: start, end: end };' +
    '}' +

    'function getPeriodRange(type, offset) {' +
    'var now = new Date();' +
    'var d = new Date(now);' +
    'if (type === "month") d.setMonth(d.getMonth() + offset);' +
    'else if (type === "quarter") d.setMonth(d.getMonth() + offset * 3);' +
    'else if (type === "halfyear") d.setMonth(d.getMonth() + offset * 6);' +
    'else if (type === "year") d.setFullYear(d.getFullYear() + offset);' +
    'var year = d.getFullYear();' +
    'var month = d.getMonth() + 1;' +
    'if (type === "month") {' +
    'var b = periodBounds(year, month, 1);' +
    'var monthNames = ["Januar","Februar","März","April","Mai","Juni","Juli","August","September","Oktober","November","Dezember"];' +
    'return { start: b.start, end: b.end, label: monthNames[month - 1] + " " + year };' +
    '} else if (type === "quarter") {' +
    'var qStart = Math.floor((month - 1) / 3) * 3 + 1;' +
    'var b2 = periodBounds(year, qStart, 3);' +
    'var quarter = Math.floor((month - 1) / 3) + 1;' +
    'return { start: b2.start, end: b2.end, label: "Q" + quarter + " " + year };' +
    '} else if (type === "halfyear") {' +
    'var hStart = month <= 6 ? 1 : 7;' +
    'var b3 = periodBounds(year, hStart, 6);' +
    'var half = month <= 6 ? 1 : 2;' +
    'return { start: b3.start, end: b3.end, label: "H" + half + " " + year };' +
    '} else {' +
    'var b4 = periodBounds(year, 1, 12);' +
    'return { start: b4.start, end: b4.end, label: "" + year };' +
    '}' +
    '}' +

    'function splitNames(str) {' +
    'return (str || "").split(" & ").map(function(s){return s.trim();}).filter(function(s){return s;});' +
    '}' +

    'function computeWinLoss(rows, mode) {' +
    'var table = {};' +
    'rows.forEach(function(row) {' +
    'if (row.mode !== mode) return;' +
    'var scoreWand = Number(row.scoreWand);' +
    'var scoreTreppe = Number(row.scoreTreppe);' +
    'if (isNaN(scoreWand) || isNaN(scoreTreppe) || scoreWand === scoreTreppe) return;' +
    'var wandWon = scoreWand > scoreTreppe;' +
    'var winners = splitNames(wandWon ? row.wandPlayers : row.treppePlayers);' +
    'var losers = splitNames(wandWon ? row.treppePlayers : row.wandPlayers);' +
    'winners.forEach(function(name){ table[name] = table[name] || {wins:0, losses:0}; table[name].wins++; });' +
    'losers.forEach(function(name){ table[name] = table[name] || {wins:0, losses:0}; table[name].losses++; });' +
    '});' +
    'var list = Object.keys(table).map(function(name){' +
    'var w = table[name].wins, l = table[name].losses;' +
    'var winrate = l === 0 ? w : w / l;' +
    'return { name: name, wins: w, losses: l, winrate: winrate };' +
    '});' +
    'list.sort(function(a,b){ return b.winrate - a.winrate; });' +
    'return list;' +
    '}' +

    'function computeOwnGoals(rows) {' +
    'var table = {};' +
    'rows.forEach(function(row) {' +
    '(row.ownGoals || "").split(",").forEach(function(entry) {' +
    'var parts = entry.split(":");' +
    'if (parts.length !== 2) return;' +
    'var name = parts[0].trim();' +
    'var count = parseInt(parts[1].trim(), 10);' +
    'if (!name || isNaN(count)) return;' +
    'table[name] = (table[name] || 0) + count;' +
    '});' +
    '});' +
    'var list = Object.keys(table).map(function(name){ return { name: name, count: table[name] }; });' +
    'list.sort(function(a,b){ return b.count - a.count; });' +
    'return list;' +
    '}' +

    'function escapeHtmlClient(s) {' +
    'return String(s).replace(/&/g,"&amp;").replace(/</g,"&lt;").replace(/>/g,"&gt;");' +
    '}' +

    'function winLossTableHtml(list) {' +
    'if (list.length === 0) return "<div id=\\"empty\\">Noch keine Ergebnisse</div>";' +
    'var html = "<table><tr><th>Spieler</th><th>S/N</th><th>Winrate</th></tr>";' +
    'list.forEach(function(row, i) {' +
    'html += "<tr><td>" + (i + 1) + ". " + escapeHtmlClient(row.name) + "</td><td>" + row.wins + "/" + row.losses + "</td><td>" + row.winrate.toFixed(2) + "</td></tr>";' +
    '});' +
    'html += "</table>";' +
    'return html;' +
    '}' +

    'function ownGoalTableHtml(list) {' +
    'if (list.length === 0) return "<div id=\\"empty\\">Noch keine Eigentore</div>";' +
    'var html = "<table><tr><th>Spieler</th><th>Eigentore</th></tr>";' +
    'list.forEach(function(row, i) {' +
    'html += "<tr><td>" + (i + 1) + ". " + escapeHtmlClient(row.name) + "</td><td>" + row.count + "</td></tr>";' +
    '});' +
    'html += "</table>";' +
    'return html;' +
    '}' +

    'function render() {' +
    'var periodRow = document.getElementById("periodRow");' +
    'if (selectedTab === 3) {' +
    'periodRow.style.display = "none";' +
    'document.getElementById("content").innerHTML = historyTableHtml(allRows.slice().sort(function(a,b){ return new Date(b.date) - new Date(a.date); }).slice(0, 30));' +
    'return;' +
    '}' +
    'periodRow.style.display = "flex";' +
    'var type = document.getElementById("periodType").value;' +
    'var range = getPeriodRange(type, periodOffset);' +
    'document.getElementById("periodLabel").textContent = range.label;' +
    'document.getElementById("nextBtn").disabled = periodOffset >= 0;' +
    'var active = allRows.filter(function(row) {' +
    'var d = new Date(row.date);' +
    'return d >= range.start && d <= range.end;' +
    '});' +
    'var content = document.getElementById("content");' +
    'if (selectedTab === 0) content.innerHTML = winLossTableHtml(computeWinLoss(active, "1vs1"));' +
    'else if (selectedTab === 1) content.innerHTML = winLossTableHtml(computeWinLoss(active, "2vs2"));' +
    'else content.innerHTML = ownGoalTableHtml(computeOwnGoals(active));' +
    '}' +

    'function historyTableHtml(list) {' +
    'if (list.length === 0) return "<div id=\\"empty\\">Noch keine Ergebnisse</div>";' +
    'var html = "<div style=\\"font-size:12px;color:#999;margin-bottom:8px\\">Letzte " + list.length + " Ergebnisse</div>";' +
    'list.forEach(function(row) {' +
    'var d = new Date(row.date);' +
    'var dateStr = ("0"+d.getDate()).slice(-2) + "." + ("0"+(d.getMonth()+1)).slice(-2) + "." + d.getFullYear();' +
    'var modeLabel = row.mode === "2vs2" ? "2 vs 2" : "1 vs 1";' +
    'html += "<div style=\\"background:white;border-radius:10px;padding:12px;margin-bottom:8px\\">";' +
    'html += "<div style=\\"display:flex;justify-content:space-between;font-size:12px;color:#999;margin-bottom:4px\\">";' +
    'html += "<span>" + modeLabel + "</span><span>" + dateStr + "</span></div>";' +
    'html += "<div style=\\"display:flex;justify-content:space-between;align-items:center\\">";' +
    'html += "<div>" + escapeHtmlClient(row.wandPlayers) + "<br><b>" + row.scoreWand + " : " + row.scoreTreppe + "</b><br>" + escapeHtmlClient(row.treppePlayers) + "</div>";' +
    'html += "<button onclick=\\"deleteRow(\'" + row.id + "\')\\" style=\\"background:#fdecea;color:#c62828;border:none;border-radius:6px;padding:8px 10px;cursor:pointer\\">🗑</button>";' +
    'html += "</div>";' +
    'if (row.ownGoals) html += "<div style=\\"font-size:12px;color:#999;margin-top:6px\\">Eigentore: " + escapeHtmlClient(row.ownGoals) + "</div>";' +
    'html += "</div>";' +
    '});' +
    'return html;' +
    '}' +

    'function deleteRow(id) {' +
    'if (!confirm("Dieses Ergebnis wirklich löschen?")) return;' +
    'fetch(SCRIPT_URL, { method: "POST", body: JSON.stringify({ id: id, deleted: true, date: "", mode: "", wandPlayers: "", treppePlayers: "", scoreWand: 0, scoreTreppe: 0, ownGoals: "" }) })' +
    '.then(function(){' +
    'allRows = allRows.filter(function(r){ return r.id !== id; });' +
    'render();' +
    '})' +
    '.catch(function(){ alert("Löschen fehlgeschlagen."); });' +
    '}' +

    'function selectTab(i) {' +
    'selectedTab = i;' +
    'for (var j = 0; j < 4; j++) document.getElementById("tab" + j).classList.remove("active");' +
    'document.getElementById("tab" + i).classList.add("active");' +
    'render();' +
    '}' +

    'function shiftPeriod(delta) {' +
    'periodOffset += delta;' +
    'if (periodOffset > 0) periodOffset = 0;' +
    'render();' +
    '}' +

    'function onPeriodTypeChange() {' +
    'periodOffset = 0;' +
    'render();' +
    '}' +

    'fetch(SCRIPT_URL + "?action=rows")' +
    '.then(function(r){ return r.json(); })' +
    '.then(function(data){ allRows = data.rows || []; render(); })' +
    '.catch(function(){ document.getElementById("content").textContent = "Fehler beim Laden."; });' +
    '</script></body></html>';
}
''';
