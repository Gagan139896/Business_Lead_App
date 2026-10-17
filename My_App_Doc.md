# Business Lead App: Final Master Document

Version 1.0 | October 2026 | Product, Technical aur Integration Specification (ek hi document me poora system)

## 0. Is document ka use

Ye document us app ka final blueprint hai jo tum bana rahe ho: ek multi-business lead management app jisme business owner signup karke apna business type chunta hai, aur app us business ke hisaab se apne aap customize ho jati hai.

Isme ye sab ek jagah hai: faisle, user flows, business templates, database design, lead sources ka integration, security, roadmap aur acceptance criteria. Ise developer, designer ya investor ko seedha de sakte ho.

**Download kaise karein:** document ke menu se Word ya PDF me export kar sakte ho.

## 1. Vision aur final faisle

### 1.1 Vision

Chhote aur medium local businesses (real estate, clinic, salon, parlour, coaching, gym, car dealer etc.) ki saari leads ek hi app me aayein, team un par kaam kare, aur owner ko dashboard me clear picture mile ki aaj kitni leads aayin, kahan se aayin aur kitni deal me badli.

### 1.2 Jo faisle ho chuke hain

| Faisla | Final answer |
| --- | --- |
| App ka model | Ek hi app, ek hi backend, ek hi codebase (multi-tenant SaaS) |
| Har business ke liye alag branded app | Nahi (white-label sirf baad me, agar koi bada client maange) |
| Customization kaise | Business type ke Template (configuration) se, code generation se nahi |
| Database approach | Shared tables + JSONB custom fields; alag schema ya database har business ka nahi |
| Google Sheets aur Apps Script | System se hata diye; sirf import ya export ke liye |
| Backend (recommendation) | Supabase (Postgres, Auth, Row Level Security, Edge Functions, Realtime) |
| Mobile app | Flutter (Android pehle) |
| Lead capture principle | "No silent loss": digital channel se aayi lead kabhi chupke se khoti nahi |

### 1.3 Jo abhi tak open hai (Section 19 me details)

Backend ka final confirmation, V1 me sirf leads ya appointments bhi, pehle kaun se 2-3 business types, aur pricing.

## 2. Users aur roles

1. **Business owner:** signup karta hai, business register karta hai, team aur sources manage karta hai, dashboard dekhta hai.
2. **Manager:** leads aur team ka kaam dekhta hai.
3. **Agent (team member):** apni assigned leads par kaam karta hai.
4. **Platform admin (tum):** templates, plans aur support manage karte ho.

| Action | Owner | Manager | Agent | Platform Admin |
| --- | --- | --- | --- | --- |
| Business settings aur template edit | Haan | Nahi | Nahi | Haan |
| Team add ya remove | Haan | Haan (agent) | Nahi | Haan |
| Saari leads dekhna | Haan | Haan | Sirf assigned | Haan (support) |
| Lead add ya edit | Haan | Haan | Haan (assigned) | Nahi |
| Lead delete | Haan | Nahi | Nahi | Nahi |
| Data export | Haan | Nahi | Nahi | Nahi |
| Dashboard | Poora | Poora | Apna | Nahi |
| Billing aur plan | Haan | Nahi | Nahi | Haan |
| Lead sources connect | Haan | Haan | Nahi | Haan |

## 3. Core concept: template-driven app

App ka code ek hi rehta hai. Har business type ka ek **Template** (JSON configuration) hota hai. Business register hote hi template us business ke account me copy ho jata hai (**Org Config**). App login ke baad Org Config padhkar apni screens banati hai: lead form ke fields, status list, filters, dashboard widgets aur labels.

1. Naya business type jodna = ek naya template banana, app update nahi.
2. Owner apna config badal sakta hai (naya field, naya status) bina app update ke.
3. Template ka naya version aane par owner ko batao, purane config ko apne aap overwrite mat karo.
4. Business type "Other" chunne par khali template milta hai jo owner khud banata hai.

## 4. User journeys

### 4.1 Signup se dashboard tak

1. **Welcome screen:** app ka naam aur Get Started.
2. **Signup:** phone number aur OTP, naam.
3. **Register your business:** business name, **business type (dropdown)**, city, business phone, logo aur brand color (optional). Dropdown ki list Platform admin ke published templates se aati hai: Real Estate, Clinic, Salon, Beauty Parlour, Coaching Institute, Gym and Fitness, Car Dealer, Interior Designer, Travel Agency, Insurance and Finance Agent, Other.
4. **Template preview:** type chunte hi dikhta hai ki is business ke liye kaun se statuses, fields aur sources set honge. Buttons: Continue ya Customize.
5. **Template apply:** backend template ko organization me copy karta hai.
6. **Connect lead sources:** business ke type ke hisaab se suggested sources (Section 10), guided wizard aur Send test lead.
7. **Team invite:** phone se agents add karo, role set karo.
8. **Dashboard:** setup checklist aur Today's Leads.
9. **Pehli lead:** jab pehli asli lead aati hai, activation complete maana jata hai.

### 4.2 Daily use

1. Lead kisi bhi source se aati hai.
2. Owner aur assigned agent ko push notification.
3. Agent call ya WhatsApp karta hai, status, notes aur next follow-up update karta hai.
4. Follow-up ke din reminder aata hai.
5. Owner dashboard me Today's Leads, funnel, sources aur conversion dekhta hai.

## 5. Business type catalog (V1 templates)

Har template me labels (shabdavali), statuses (kind: open, won, lost), key fields, default sources aur dashboard widgets hote hain.

| Business type | Lead ko kya kahein | Statuses | Key fields |
| --- | --- | --- | --- |
| Real Estate | Lead | New, Contacted, Hot, Site Visit, Negotiation, Won, Lost | Budget, Property type, BHK, Location, Loan chahiye, Kab tak lena hai |
| Clinic | Patient enquiry | New, Called, Appointment Booked, Visited, Treatment Started, Lost | Age, Concern, Preferred date aur time, Doctor, First visit ya follow-up |
| Salon | Customer | New, Contacted, Booked, Visited, Repeat Customer, Lost | Service, Preferred stylist, Preferred time |
| Beauty Parlour | Customer | New, Contacted, Booked, Visited, Package Sold, Lost | Service, Occasion, Event date, Budget |
| Coaching Institute | Student enquiry | New, Counselled, Demo Class, Admission Pending, Admitted, Lost | Student class, Course, Parent name, Board, Preferred batch |
| Gym and Fitness | Member enquiry | New, Contacted, Trial Booked, Trial Done, Joined, Lost | Goal, Plan interest, Trial date, Age |
| Car Dealer | Customer | New, Contacted, Test Drive, Negotiation, Won, Lost | Car model, New ya Used, Budget, Exchange car, Finance chahiye |
| Interior Designer | Project lead | New, Contacted, Site Visit, Quote Sent, Won, Lost | Property type, Area, Budget, Rooms, Timeline |
| Travel Agency | Enquiry | New, Contacted, Quote Sent, Booked, Travelled, Lost | Destination, Travel dates, Travellers, Budget |
| Insurance and Finance Agent | Prospect | New, Contacted, Meeting, Proposal Sent, Won, Lost | Product, Age, Preferred call time |
| Other | Lead | New, Contacted, Interested, Follow-up, Won, Lost | Name, Phone, Notes (aur owner ke jode hue fields) |

**Sabme common fields:** Name, Phone, Source, Assigned to, Next follow-up, Notes, Deal value (Won par), Lost reason (Lost par).

**Default sources:** Meta Ad, Instagram, Facebook, Google Ads, Website, WhatsApp, Phone Call, Walk-in, Referral, Other.

**Sensitive data note:** clinic jaise templates me health se judi jankari aa sakti hai. Wahan sirf zaruri fields rakho, form me consent ka line daalo aur kanooni salaah lo. Insurance aur finance me bhi sirf zaruri jankari lo.

## 6. Template configuration schema

```json
{
  "schema_version": 1,
  "template_version": 3,
  "type": "clinic",
  "display_name": "Clinic",
  "labels": { "lead": "Patient enquiry", "leads": "Patient enquiries", "won": "Treatment Started" },
  "statuses": [
    { "key": "new", "label": "New", "kind": "open", "color": "#2F80ED" },
    { "key": "booked", "label": "Appointment Booked", "kind": "open", "color": "#E0359B" },
    { "key": "started", "label": "Treatment Started", "kind": "won", "color": "#12A05C" },
    { "key": "lost", "label": "Lost", "kind": "lost", "color": "#E5484D" }
  ],
  "fields": [
    { "key": "age", "label": "Age", "type": "number", "required": false, "min": 0, "max": 120 },
    { "key": "concern", "label": "Concern", "type": "select", "required": true, "options": ["Skin", "Dental", "General"] },
    { "key": "preferred_time", "label": "Preferred time", "type": "datetime", "required": false }
  ],
  "list_columns": ["name", "phone", "concern", "status"],
  "filters": ["status", "source", "assigned_to", "followup"],
  "lost_reasons": ["Price high", "Not responding", "Went elsewhere", "Not interested"],
  "sources": ["Meta Ad", "Google Ads", "Website", "WhatsApp", "Walk-in", "Referral"],
  "dashboard": ["today_leads", "funnel", "status_split", "sources", "followups_due", "conversion"]
}
```

**Supported field types (V1):** text, textarea, number, currency, phone, email, select, multiselect, date, datetime, checkbox, user.

**Config ke niyam**

1. Har config me kam se kam ek won aur ek lost status ho (analytics inhi par chalta hai).
2. Field ki key kabhi nahi badalti (rename sirf label badalta hai), taaki purana data na toote.
3. Field delete ki jagah hide hota hai.
4. Server config ko schema se validate kare; galat config save na ho.
5. App unknown field type ya widget ko ignore kare, crash na kare.
6. Conditional visibility (visible\_if) V1 me sirf simple equals ke liye.

## 7. Dynamic schema strategy: alag business, alag columns

Property ki leads ke columns salon se alag hote hain. Isse handle karne ka tareeka:

1. **Ek hi `leads` table** sab businesses ke liye. Fixed columns: id, organization\_id, name, phone, source, status\_key, assigned\_to, next\_followup\_at, deal\_value, lost\_reason, created\_at.
2. **Business-specific fields `custom_fields` (JSONB) me.** Property: budget, bhk, location. Salon: service, stylist, preferred\_time.
3. **Config batata hai** kaun sa field kya hai, kaisa dikhega aur kaise validate hoga.
4. **Save par validation:** server lead ke fields ko org config se check karta hai (required, type, options). Unknown keys reject ya ignore.
5. **Filter aur search:** custom field par query (jaise custom\_fields->>'service') chalti hai; jin fields par roz filter lagta hai unpar index lagao (GIN ya expression index).
6. **Dashboard:** common cheezein (status, source, date, deal value) fixed columns se ginti hoti hain, isliye har business me chalti hain. Custom field par report ek config widget se define hoti hai.
7. **Field badalne par** purani leads me wo field khali rehta hai; data safe rehta hai.
8. **Jab JSONB kaafi nahi:** agar business ko bilkul alag structure chahiye (clinic ke appointments, car dealer ki inventory), to ek generic `records` table (entity\_type + JSONB) ya alag module table banao. V1 me sirf leads.

**Kyun alag schema ya database har business ka nahi:** 1,000 businesses = 1,000 migrations, jisse maintenance, backup aur cost bahut badh jate hain.

## 8. Functional requirements

### 8.1 Auth aur account

- Phone OTP signup aur login; secure session; sab devices se logout.
- Ek user kai businesses ka member ho sakta hai aur business switch kar sakta hai.
- In-app account deletion (store ki requirement) aur data policy ke hisaab se hataya jaye.
- Language: Hindi aur English.

### 8.2 Business registration aur template

- Business type dropdown dynamic (backend se), app update nahi chahiye.
- Type chunne par template preview, register par template copy aur version save.
- Owner config edit kare: field add, rename, reorder, hide; status add, rename, reorder (won aur lost types delete na ho sakein); source add; lost reasons.
- Template ka naya version aane par Update available notice.

### 8.3 Leads

- List with search (naam, phone), filters (status, source, assigned, date, follow-up due), sort.
- Add lead form template ke fields se dynamic.
- Phone 10 digit validate aur normalize; ek business me duplicate phone par nayi lead nahi, existing lead dikhao.
- Lead detail: fields, status badalna, notes, call button, WhatsApp button, assign, next follow-up, timeline.
- Status change par activity log. Won par deal value, Lost par lost reason zaruri.
- Bulk assign aur status change (manager, owner).
- CSV import (column mapping ke saath) aur CSV export (sirf owner).

### 8.4 Follow-ups

- Har lead par next follow-up date aur time.
- Screen: Overdue, Aaj, Aane wale. Follow-up ke time par push reminder.
- Nayi lead par default follow-up aaj ka.

### 8.5 Team

- Phone se invite, role set; member deactivate par leads reassign.
- Assignment manual, aur optional round-robin.

### 8.6 Notifications

- Nayi lead par push, follow-up reminder, daily summary (optional), aur user ke settings me on ya off.

### 8.7 Billing

- Free trial (jaise 14 din) aur plans (Free, Pro, Business) jinki limits server par enforce hon (leads per month, users, sources).
- Razorpay se subscription aur payment status webhook se sync.

### 8.8 Platform admin panel (web)

- Templates banana, edit, version publish; draft me test.
- Organizations, plan aur usage dekhna; support ke liye read-only access (audit log ke saath).
- Feature flags aur plan limits.

## 9. Dashboard spec

Dashboard widgets template ke dashboard list se load hote hain (dynamic widget registry). Date filter: Aaj, Kal, 7 din, 30 din, custom.

| Widget | Meaning |
| --- | --- |
| Today's Leads | Aaj (organization ke timezone me) ki leads, kal se tulna ke saath |
| Total Leads | Selected period ki saari leads |
| Funnel | Statuses ke hisaab se leads (stage order me) |
| Status Split | Status ka donut chart |
| Lead Sources | Source-wise leads (first touch ke hisaab se, setting se badal sakta hai) |
| Follow-ups Due | Aaj aur overdue follow-ups ki list |
| Conversion % | Won leads / total leads |
| Revenue | Won leads ki deal value ka total |
| Cost per Lead aur ROI | Ad spend manual entry se: spend / leads, aur (revenue - spend) / spend |
| Lost Reasons | Lost leads ke karan |
| Source Health | Kaun se sources connected hain aur kin par dhyan chahiye |

Agent ko sirf apne numbers dikhte hain. Numbers server side SQL aggregation se aate hain (poora data app me nahi laate), isse dashboard tez rehta hai.

**Today's Leads query ka tareeka:** organization ke timezone me aaj ki date par created\_at filter, deleted leads ko chhodkar.

## 10. Lead sources aur integrations

**Principle: "No silent loss".** "0% lead miss" ka vaada poori tarah nahi diya ja sakta, kyunki walk-in, kisi ke personal phone ki WhatsApp chat ya zabani enquiry tabhi system me aati hai jab staff use daale. Lekin jo lead kisi digital channel se system tak pahunchti hai wo kabhi chupke se nahi khoti, aur baaki channels ke liye lead daalna 10 second ka kaam banta hai.

### 10.1 Pipeline

1. **Connector (adapter):** har source ka alag adapter (Meta, Google Ads, Website, WhatsApp, Calls, Email, Portals, Manual).
2. **Raw events store:** webhook aate hi payload bina badle save hota hai, tab HTTP 200 jata hai.
3. **Normalizer:** alag formats ko ek standard lead format me badalta hai.
4. **Validator aur dedupe:** phone check, spam filter, duplicate check.
5. **Lead create ya merge:** nayi lead, ya existing lead me nayi touchpoint.
6. **Notifier:** push notification aur activity log.
7. **Monitor:** source health, retries aur alerts.

Naya source jodna = ek naya adapter likhna. Baaki pipeline wahi rehti hai.

### 10.2 Source catalog

Platform ke rules aur APIs badalte rehte hain. Har source banane se pehle uski current official documentation verify karo.

| Source | Kaise connect hoga | Kya chahiye | Phase |
| --- | --- | --- | --- |
| Manual entry aur quick add | In-app form, sirf naam aur phone | Kuch nahi | 1 |
| Website form | Hosted form, JS snippet ya API (organization key ke saath) | Website par code ya plugin | 1 |
| Generic webhook | Typeform, Tally, Jotform, landing pages, Zapier, Make | Webhook URL aur key | 1 |
| Google Form | Apps Script ya Zapier se webhook | Chhota script | 1 |
| CSV import | File upload aur column mapping | CSV | 1 |
| QR code ya short link | Har campaign ka alag QR jo hosted form kholta hai | Kuch nahi | 1 |
| Google Ads lead form | Lead form extension ka webhook (URL aur key) | Google Ads access | 2 |
| Meta Lead Ads | Meta leadgen webhook + Graph API | Meta app, Page access, permissions (aksar App Review) | 2 |
| Inbound email | Har business ka alag email address, parse hoke lead | Forwarding rule | 2 |
| WhatsApp | WhatsApp Business Platform (Cloud API), pehla inbound message = lead | Business verification, number setup | 3 |
| Calls (inbound aur missed) | Cloud telephony ya call tracking provider ka webhook | Provider account, virtual number | 3 |
| Portals (99acres, MagicBricks, Housing, JustDial, IndiaMART, Practo...) | Portal ki API ya CRM integration, nahi to lead email parse | Portal account, plan par nirbhar | 3 |
| Instagram DMs aur Facebook comments | Meta messaging aur comments webhooks | Meta permissions aur review | 3 |
| Walk-in, referral, events | Quick add, QR form, business card scan (OCR) | Staff ki aadat | 1 |

Phase 1 me wahi rakho jo kisi platform approval ke bina chalte hain. Meta aur WhatsApp ki approval me waqt lag sakta hai, isliye unki application Phase 1 ke dauran hi shuru kar do.

### 10.3 Reliability design

1. **Raw event pehle save, phir process.**
2. **Idempotency:** har event ki unique key (source + external\_id, jaise Meta ki leadgen\_id). Same event dobara aaye to duplicate lead nahi banti.
3. **Retries:** fail hone par exponential backoff (jaise 1 min, 5 min, 30 min, 2 ghante, 12 ghante).
4. **Dead-letter queue:** retries ke baad bhi fail ho to failed\_events me jaye, aur alert mile. Event delete nahi hota.
5. **Backfill:** Meta aur Google jaise sources se har 10-15 minute me pichle kuch ghanton ki leads API se mangwao, taaki webhook miss ho to bhi lead mil jaye.
6. **Heartbeat alerts:** kisi active source se normal pattern se zyada der tak koi lead na aaye to owner ko alert.
7. **Token expiry watch:** Meta aur Google ke access tokens expire ya revoke ho sakte hain; reminder, refresh aur Reconnect flow. Silent loss ki sabse badi wajah yahi hoti hai.
8. **Source health screen:** har source ka status (Connected, Warning, Disconnected), last lead kab aayi, pichle 24 ghante ke errors, aur Test lead button.
9. **Spam filter:** phone validation, rate limit, honeypot field (website form me), suspicious lead ko flag karna (delete nahi).

### 10.4 Normalized lead format

```json
{
  "organization_id": "...",
  "source": "meta_lead_ads",
  "external_id": "leadgen_123456",
  "received_at": "2026-10-13T10:15:00Z",
  "name": "Rahul Sharma",
  "phone": "98XXXXXXXX",
  "fields": { "budget": "50L-1Cr", "requirement": "2 BHK" },
  "attribution": { "campaign": "Mohali 2BHK", "adset": "28-55 Tricity", "ad": "Reel 1", "utm": { "source": "instagram", "medium": "paid" } },
  "consent": { "given": true, "text": "Form submit se sampark ki anumati" }
}
```

Source ke fields ko template ke fields se jodne ke liye **field mapping screen** hogi.

### 10.5 Dedupe aur multiple touchpoints

1. Phone normalize karo (last 10 digit).
2. Same organization me same phone par lead pehle se hai to nayi lead mat banao; existing lead me touchpoint jodo (kaun sa source, kab, kaun sa campaign).
3. Owner ko batao: "Rahul ne WhatsApp par bhi sampark kiya."
4. First touch aur latest touch dono save karo.
5. Phone na mile (sirf email) to email se dedupe aur lead ko Needs phone flag karo.

### 10.6 Per-source notes

- **Website form:** key browser me public mat rakho (server side ya limited-permission key aur domain allow-list). Honeypot aur rate limit lagao.
- **Generic webhook:** POST /intake/{organization\_id}, header X-Intake-Key; payload field mapping se template se judta hai.
- **Google Ads:** lead form extension me webhook URL aur key; Send test data se test.
- **Meta Lead Ads:** client Connect with Facebook se Page aur forms ka access deta hai (OAuth); leadgen webhook subscribe karo, signature verify karo, Graph API se lead details lao, aur backfill job chalao.
- **WhatsApp:** pehle simple click-to-WhatsApp link (prefilled message) aur staff app me lead daale; baad me official Cloud API. Bina permission ke bulk message nahi, aur 24 ghante ke window ke niyam follow karo. Number ko API aur WhatsApp Business app me ek saath chalane ke rules verify karo.
- **Calls:** cloud telephony provider se virtual number; inbound aur missed call webhook se lead; missed call par turant callback flag; har campaign ka alag number = attribution. Call recording ke kanooni niyam verify karo.
- **Portals:** pehle API ya CRM integration dekho; nahi to lead email parse karo; format badalne par alert.
- **Inbound email:** har business ka ek address; parse fail ho to Needs review me save, delete nahi.

### 10.7 Business type ke hisaab se suggested sources

| Business type | Pehle ye sources jodo |
| --- | --- |
| Real Estate | Meta Lead Ads, Google Ads, website, portals, calls, WhatsApp |
| Clinic | Calls, Google Ads, WhatsApp, directory (Practo, JustDial), website, Instagram |
| Salon aur Parlour | Instagram DM aur WhatsApp, calls, walk-in QR, Meta ads |
| Coaching | Meta Lead Ads, WhatsApp, calls, website, walk-in |
| Car Dealer | Meta Lead Ads, Google Ads, portals, calls, WhatsApp, walk-in |
| Other | Manual, website form, generic webhook, WhatsApp |

## 11. Data model aur starter SQL

### 11.1 Tables

1. **organizations:** id, name, business\_type, city, logo\_url, brand\_color, timezone, plan, template\_version, created\_at.
2. **profiles:** id (user), name, phone, language, device tokens.
3. **memberships:** user\_id, organization\_id, role, status.
4. **business\_templates:** type, version, display\_name, config (JSON), status (draft, published).
5. **org\_config:** organization\_id, config (JSON), based\_on\_template\_version.
6. **leads:** id, organization\_id, name, phone, phone\_normalized, source, first\_source, status\_key, assigned\_to, next\_followup\_at, deal\_value, lost\_reason, custom\_fields (JSONB), created\_by, created\_at, updated\_at, deleted\_at.
7. **lead\_activities:** lead\_id, user\_id, type, data (JSONB), created\_at.
8. **lead\_touchpoints:** lead\_id, source\_id, external\_id, attribution (JSONB), created\_at.
9. **lead\_sources:** id, organization\_id, type, name, status, config, credentials\_ref (secure storage ka reference), last\_success\_at, last\_error\_at.
10. **raw\_events:** id, organization\_id, source\_id, external\_id, payload (JSONB), status, attempts, received\_at, processed\_at; unique (source\_id, external\_id).
11. **failed\_events, field\_mappings, consent\_records, ad\_spend, subscriptions, notifications\_log, audit\_logs.**

### 11.2 Starter SQL (Postgres ya Supabase)

Ye sirf shuruaati skeleton hai. Production me lagane se pehle review, testing aur migrations ke saath chalao.

```sql
create extension if not exists pgcrypto;

create table organizations (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  business_type text not null,
  city text,
  timezone text not null default 'Asia/Kolkata',
  plan text not null default 'trial',
  template_version int,
  created_at timestamptz not null default now()
);

create table memberships (
  user_id uuid not null references auth.users(id) on delete cascade,
  organization_id uuid not null references organizations(id) on delete cascade,
  role text not null check (role in ('owner','manager','agent')),
  status text not null default 'active',
  primary key (user_id, organization_id)
);

create table business_templates (
  type text not null,
  version int not null,
  display_name text not null,
  config jsonb not null,
  status text not null default 'draft',
  primary key (type, version)
);

create table org_config (
  organization_id uuid primary key references organizations(id) on delete cascade,
  config jsonb not null,
  based_on_template_version int,
  updated_at timestamptz not null default now()
);

create table leads (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references organizations(id) on delete cascade,
  name text,
  phone text,
  phone_normalized text,
  source text,
  first_source text,
  status_key text not null,
  assigned_to uuid references auth.users(id),
  next_followup_at timestamptz,
  deal_value numeric,
  lost_reason text,
  custom_fields jsonb not null default '{}',
  created_by uuid,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz
);

create unique index leads_org_phone_uq
  on leads (organization_id, phone_normalized)
  where deleted_at is null and phone_normalized is not null;
create index leads_org_status on leads (organization_id, status_key);
create index leads_org_created on leads (organization_id, created_at desc);
create index leads_org_followup on leads (organization_id, next_followup_at);
create index leads_custom_gin on leads using gin (custom_fields jsonb_path_ops);

create table raw_events (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references organizations(id) on delete cascade,
  source_id uuid,
  external_id text,
  payload jsonb not null,
  status text not null default 'received',
  attempts int not null default 0,
  received_at timestamptz not null default now(),
  processed_at timestamptz
);
create unique index raw_events_dedupe on raw_events (source_id, external_id)
  where external_id is not null;

-- Row Level Security helpers
create function org_role(org uuid) returns text
language sql stable security definer set search_path = public as $$
  select role from memberships
  where organization_id = org and user_id = auth.uid() and status = 'active'
$$;

alter table leads enable row level security;

create policy leads_select on leads for select using (
  org_role(organization_id) in ('owner','manager')
  or (org_role(organization_id) = 'agent' and assigned_to = auth.uid())
);
create policy leads_insert on leads for insert with check (org_role(organization_id) is not null);
create policy leads_update on leads for update using (
  org_role(organization_id) in ('owner','manager')
  or (org_role(organization_id) = 'agent' and assigned_to = auth.uid())
);
create policy leads_delete on leads for delete using (org_role(organization_id) = 'owner');
```

Baaki tables par bhi RLS lagao. Webhook se aane wale inserts server side (service role) se hote hain, client se nahi. Secrets aur tokens sirf server par rakho.

**Today's Leads query ka example**

```sql
select count(*) from leads l
join organizations o on o.id = l.organization_id
where l.organization_id = $1 and l.deleted_at is null
  and (l.created_at at time zone o.timezone)::date = (now() at time zone o.timezone)::date;
```

## 12. Tech stack aur app architecture

- **Flutter** (Android pehle, iOS baad me), state management Riverpod, navigation go\_router, models freezed + json\_serializable.
- **Backend:** Supabase (Postgres, Auth, RLS, Edge Functions, Realtime). Alternative Firebase, par ek chuno aur uspe tik jao.
- **Push:** Firebase Cloud Messaging. **Payments:** Razorpay. **Monitoring:** Sentry ya Crashlytics. **Analytics:** Firebase Analytics ya PostHog.
- **CI/CD:** GitHub Actions ya Codemagic; environments dev, staging, prod alag.

**Flutter structure**

1. Feature-first folders: auth, onboarding, leads, dashboard, team, sources, settings, billing.
2. Repository pattern: UI seedha backend ko nahi bulati.
3. **ConfigRepository:** login ke baad org config download aur cache, version badalne par refresh.
4. **FormRenderer** (config ke fields se form), **LeadListRenderer** (list\_columns aur filters), **DashboardRenderer** (WidgetRegistry se widgets), aur unknown cheez ko skip karna.
5. Labels config se, hardcoded nahi. Brand color se theme.
6. Localization: Hindi aur English (ARB files).
7. Offline: lead list ka read-only cache; offline updates ki sync queue (V1.1).
8. Har network call ke liye loading, empty aur error state aur retry.

## 13. Security, privacy aur compliance

1. **Row Level Security** har table par; client par bharosa nahi, rules database me.
2. Roles ke alag permissions (delete aur export sirf owner).
3. Secrets, API keys aur tokens sirf server par; app me sirf public anon key.
4. Webhooks par signature ya secret verify aur rate limiting; OTP abuse protection.
5. HTTPS, encryption at rest, daily backups aur restore ka test.
6. **Privacy:** lead ka data personal data hai. Privacy policy, lead forms me consent line, data delete aur export ka tareeka, aur retention niyam. India ke DPDP Act aur Meta, Google, WhatsApp ke platform rules ke liye kanooni salaah lo.
7. **Store rules:** privacy policy URL, Play Data Safety aur App Store privacy details sahi bharna, aur in-app account deletion dena zaruri hota hai (apne time par verify karo).
8. Audit logs sensitive actions ke liye (export, delete, role change, source connect ya disconnect).

## 14. Non-functional requirements

1. **Performance:** lead list 1 second ke andar (pehle 50 leads, pagination); dashboard 2 second ke andar (server side aggregation).
2. **Reliability:** webhook lead kabhi khona nahi chahiye; retry aur dead-letter.
3. **Scalability:** indexes, aur multi-tenant isolation tests.
4. **Observability:** crash reporting, API error monitoring, processing delay (event aane se lead dikhne tak) ke alerts.
5. **Usability:** bade tap targets, kam internet par chalna, simple Hinglish ya Hindi text.
6. **Compatibility:** Android pehle, aur chhote phones; iOS Phase 3.

## 15. Screens

1. Splash, Welcome, Signup, OTP
2. Register Business (dropdown), Template Preview
3. Connect Sources (wizard, test lead), Source Health
4. Dashboard (date filter, widgets, setup checklist)
5. Leads List, Lead Detail, Add or Edit Lead, Quick Add
6. Follow-ups
7. Team (list, invite, role)
8. Settings: Business profile, Template editor (fields, statuses, sources, lost reasons), Ad spend, Notifications, Language, Subscription, Export, Delete account
9. Import Leads (CSV mapping)
10. Subscription aur Paywall
11. Error, offline aur empty states

## 16. Analytics events

signup\_started, signup\_completed, business\_registered (with type), template\_customized, source\_connected, test\_lead\_sent, first\_lead\_received, lead\_status\_changed, followup\_completed, team\_member\_invited, export\_clicked, subscription\_started. Inse activation funnel (signup se pehli lead tak) measure hota hai.

## 17. Acceptance criteria

1. **Registration:** dropdown me published business types dikhein; Real Estate chunne par uske statuses aur fields preview me dikhein; register ke baad Add Lead form me wahi fields aayein.
2. **Different business, different format:** Clinic aur Salon ke accounts me form, statuses, labels aur dashboard alag dikhein.
3. **Data isolation:** ek organization ka user doosre ki leads, sources ya events kisi bhi tareeke se (list, ID, API) nahi dekh paye.
4. **Intake:** sahi key ke saath webhook par lead 5 second ke andar app me dikhe aur push aaye; galat key par 401.
5. **Idempotency aur dedupe:** same event 2 baar aaye to 1 lead; same phone doosre source se aaye to touchpoint judta hai, nayi lead nahi.
6. **Reliability:** processing error par raw event save rahe, retry ho, 5 retries ke baad failed\_events me aaye aur alert jaye; webhook band (simulate) karne par bhi backfill 15 minute me lead laye.
7. **Alerts:** source ka token expire ho to owner ko 1 ghante ke andar alert.
8. **Dashboard:** Today's Leads sirf aaj (organization ke timezone me) ki leads ginta hai aur kal se tulna dikhata hai.
9. **Template change:** owner naya field jode to bina app update ke form me aa jaye aur purani leads ka data na tute.
10. **Roles:** agent sirf apni assigned leads dekhe aur delete ya export na kar paye.

## 18. Roadmap

**Phase 1: MVP (8-10 hafte)**

- Auth (phone OTP), organization, templates (Real Estate, Clinic, Other).
- Leads CRUD, status, follow-ups, dashboard (Today's Leads, Funnel, Sources).
- Intake pipeline (raw events, dedupe, retry), manual add, website form, generic webhook, Google Form, CSV import, source health.
- RLS aur roles, push notifications.
- 5-10 asli businesses ke saath closed beta. Meta aur WhatsApp ki approval ki application shuru.

**Phase 2 (4-6 hafte)**

- Salon, Parlour, Coaching, Gym, Car Dealer, Interior, Travel, Insurance templates; template editor.
- Team invite aur roles, CSV export.
- Google Ads, Meta Lead Ads (OAuth, webhook, backfill), inbound email, field mapping.
- Ad spend aur ROI.

**Phase 3**

- Subscriptions (Razorpay), WhatsApp Cloud API, calls (telephony), portals, Instagram DMs.
- Reports, iOS, aur (zaroorat par) white-label.

## 19. Risks aur open decisions

**Risks**

1. Bahut zyada configurability app ko complex bana deti hai; V1 me limited field types rakho.
2. Template badlav se purana data ya reports toot sakte hain; key stability aur versioning ke niyam follow karo.
3. Health aur financial jaisi sensitive jankari ka compliance risk; sirf zaruri fields lo.
4. Meta aur WhatsApp ki approval me deri ya shartein badal sakti hain; Phase 1 inpe nirbhar na ho.
5. Portals ki API ya email format badalne se parsing tootegi; monitoring zaruri hai.
6. Client ki galti (token revoke, number badla) se leads rukti hain; alerts aur Reconnect flow zaruri hai.
7. Spam leads se confusion aur kharcha; validation aur flagging.

**Open decisions (final karne ke liye)**

1. Backend: Supabase ya Firebase (recommendation: Supabase).
2. V1 me sirf leads, ya appointments aur bookings bhi? (Appointments chahiye to generic records design lena hoga.)
3. Phase 1 ke liye kaun se 2-3 business types (suggestion: Real Estate, Clinic, Other)?
4. Pehle kaun se 3-4 lead sources (suggestion: manual, website, Google Form, Meta, Google Ads)?
5. Pricing aur plan limits.
6. App ka naam aur branding; UI language (Hindi, Hinglish, English).
7. WhatsApp aur telephony ke providers, aur unka kharcha kaun uthayega.
8. Source health alerts kis channel par (push, SMS, WhatsApp, email)?

## 20. Shuru karne ka checklist (pehle 2 hafte)

1. Open decisions (Section 19) par faisla karo aur is document me update karo.
2. Supabase project banao (dev aur staging), starter SQL (Section 11) chalao, aur RLS ke tests likho.
3. Real Estate aur Clinic ke template JSON final karo aur business\_templates me daalo.
4. Flutter project banao (flavors, Riverpod, go\_router), signup se business registration tak ka flow banao.
5. Config-driven Add Lead form (FormRenderer) aur Today's Leads dashboard widget banao.
6. Intake endpoint (raw events, dedupe, retry) aur ek Google Form ya website form se test lead jodo.
7. Meta Developer app aur WhatsApp Business verification ki application shuru karo.
8. 3-5 asli businesses ko beta ke liye line up karo.

## 21. Glossary

- **Organization:** ek business ka account.
- **Template:** business type ka default format (JSON).
- **Org Config:** template ki copy jo business ne apne hisaab se badli.
- **Lead:** ek potential customer ki enquiry.
- **Status kind:** open, won ya lost (analytics ke liye).
- **Touchpoint:** ek lead ka ek source se sampark.
- **RLS:** Row Level Security, database level par data access ke niyam.
- **Webhook:** ek URL jahan koi doosra system lead bhejta hai.
- **Idempotency:** same event dobara aaye to bhi sirf ek hi baar kaam hona.
- **Backfill:** missed events ko API se baad me dobara mangwana.
