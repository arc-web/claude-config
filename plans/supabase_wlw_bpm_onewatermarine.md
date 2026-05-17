# Supabase: WLW/BPM/OneWater Dealership Setup

## Context

8 new WLW Discord channels created for Blue Pixel Media (BPM) → One Water Marine dealerships. Supabase needs companies + client records for each dealership to match existing onewatermarine pattern. This wires the full relationship: ARC → BPM (intermediate) → OWM dealerships (end clients).

---

## Confirmed Domain → Channel Map (from Olly's Discord messages)

| Company | Domain | Discord Channel | Channel ID |
|---------|--------|----------------|------------|
| Garden State Yacht Sales | gardenstateyachtsales.com | 🚤-wlw-bpm-gardenstate | 1503445447170326601 |
| Norfolk Marine | norfolkmarine.com | 🚤-wlw-bpm-norfolkmarine | 1503445450680828055 |
| Slalom Shop | slalomshop.com | 🚤-wlw-bpm-slalomshop | 1503445453516050575 |
| SMG Boats | smgboats.com | 🚤-wlw-bpm-smgboats | 1503445457295376507 |
| South Shore Marine | southshoremarine.com | 🚤-wlw-bpm-southshore | 1503445460608745502 |
| Sundance Marine | sundancemarineusa.com | 🚤-wlw-bpm-sundancemarine | 1503445463586705418 |
| Sunrise Marine | sunrisemarine.com | 🚤-wlw-bpm-sunrisemarine | 1503445483140550846 |
| One Water Yacht Group | owyg.com | 🚤-wlw-bpm-onewateryachtgroup | 1503445487292776598 |

---

## Existing Supabase State

| Record | ID | Notes |
|--------|-----|-------|
| BPM company | `e91526e7-5ee8-4c55-aa82-0143ab951b23` | company_type="partner", use this (not BluePixelMedia.io duplicate) |
| onewatermarine company | `f16530db-3c9f-47af-9937-92cd4a6af129` | company_type="client", no website set |
| onewatermarine client | `1fc32b02-2f26-4751-a576-3a5048dc4595` | relationship_type="WLW", intermediate_agency_id=BPM, discord=1478284274049224774, status_google_ads="Live" |
| BluePixelMedia.io | `1486347a-329e-4e31-8319-39956f44d548` | Duplicate of BPM - do NOT use for new records |
| 8 dealership companies | — | **None exist yet** |
| 8 dealership client records | — | **None exist yet** |

---

## What To Insert

### Step 1 — Create 8 dealership companies

Each row in `companies`:
```
company_name: <name>
company_type: "client"
website: <domain with https://>
parent_company_id: f16530db-3c9f-47af-9937-92cd4a6af129  ← onewatermarine
```

| company_name | website |
|---|---|
| Garden State Yacht Sales | https://www.gardenstateyachtsales.com |
| Norfolk Marine | https://www.norfolkmarine.com |
| Slalom Shop | https://www.slalomshop.com |
| SMG Boats | https://www.smgboats.com |
| South Shore Marine | https://www.southshoremarine.com |
| Sundance Marine | https://www.sundancemarineusa.com |
| Sunrise Marine | https://www.sunrisemarine.com |
| One Water Yacht Group | https://www.owyg.com |

### Step 2 — Create 8 client records

Each row in `clients` (pattern matches existing onewatermarine client record):
```
company_id: <new dealership company UUID from step 1>
intermediate_agency_id: e91526e7-5ee8-4c55-aa82-0143ab951b23  ← BPM
relationship_type: "WLW"
status: "active"
status_whitelabel: "Live"
discord_channel_id: <channel ID from table above>
```

### Step 3 — Update BPM company record (optional cleanup)

Set website on `e91526e7`: `https://bluepixelmedia.io/` (from the BluePixelMedia.io duplicate entry).

### Step 4 — Update onewatermarine company record

Set website: leave blank (no single OWM group website; owyg.com belongs to One Water Yacht Group dealership specifically).

---

## How

Use Supabase REST API with service key from `op item get ghte3t4exbdb2prbnbzmvll7iq --vault Zeroclaw`.

```
POST https://pqwfnhbltsygwaiefnru.supabase.co/rest/v1/companies
POST https://pqwfnhbltsygwaiefnru.supabase.co/rest/v1/clients
```

Script: Python loop — insert companies, capture returned UUIDs, insert client records with those UUIDs.

---

## Verification

After insert:
```sql
SELECT c.company_name, c.website, cl.discord_channel_id, cl.relationship_type, cl.status_whitelabel
FROM clients cl
JOIN companies c ON c.id = cl.company_id
WHERE cl.intermediate_agency_id = 'e91526e7-5ee8-4c55-aa82-0143ab951b23'
ORDER BY c.company_name;
```
Expect 9 rows (existing onewatermarine + 8 new dealerships).

---

## Out of scope

- Merging BluePixelMedia.io + BPM duplicates (separate cleanup task)
- Google Ads / ClickUp / Plane IDs (not available yet)
