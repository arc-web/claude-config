---
name: Plane client project structure
description: How client work is organized in Plane - workspace > business division project > client module
type: project
originSessionId: 9ae3ac9b-afd9-492d-a109-07c3b8188200
---
Client work in Plane follows a 3-level hierarchy:

**Workspace:** `clients` (slug: clients)
**Project:** business division (e.g. ARC, BluePixel, Moonraker, BlueGorilla)
**Module:** individual client name (e.g. TheraPPC, CollabMedSpa, ProximaHire)

Issues live on the project, scoped to the client via module assignment.

**Project UUIDs (verified live 2026-05-18):**
- ARC = `e05a2d3e-502f-4b5a-bac5-8ce189e41b21`
- BLPX = `23228989-849b-418a-b344-9a7c565d5ad1`
- BLGR = `2ccf605e-6474-4df4-95da-76a70121f387`
- MOON = `8a64261f-f129-4e67-8976-b3b116cf54d4`
- TMPL = `b7c7c9d8-2be5-44be-ad0d-3682f14ef905`

**ARC project modules (verified live 2026-05-18):**
- AiBrainBuilders (ARC) = `0059233e-b1de-4ea3-a84e-d16c99b9b1ba`
- TheraPPC = `5bb36ae6-501b-4104-b97a-46f34802280a`
- CollabMedSpa (ARC) = `4aa76c96-06cf-4485-87db-f70881d6ce1c`
- ProximaHire (ARC) = `6a4735c8-dd4f-41c4-8081-85566c136bca`
- FDLXibalba (ARC) = `f8c5623a-a4a0-4ee6-97c1-5535331178ec`
- AdvertisingReportCard (ARC) = `793c48d8-3330-4b21-b2af-085432c4dced`
- SFBayAreaMoving (ARC) = `0109579c-3ed0-4443-9d5c-5d14171df9ea`

**Example (live):**
- clients workspace → ARC project → TheraPPC module → ARC-1 through ARC-8

**Why:** Multiple clients may fall under the same agency division/owner. Project = the operator. Module = the client engagement.

**How to apply:** When creating client work tasks, always assign to the correct project (business division) AND link to the client's module. If client module doesn't exist yet, create it first. Use `plane new PROJ "title" --module ClientName` or raw API with `module_ids`.

Full state UUIDs per project: `arc-web/plane-pm-agent/API.md`.
