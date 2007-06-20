BEGIN;

CREATE OR REPLACE VIEW reporter.classic_current_circ AS
SELECT	cl.shortname AS circ_lib,
	cl.id AS circ_lib_id,
	circ.xact_start AS xact_start,
	circ_type.type AS circ_type,
	cp.id AS copy_id,
	cp.circ_modifier,
	ol.shortname AS owning_lib_name,
	lm.value AS language,
	lfm.value AS lit_form,
	ifm.value AS item_form,
	itm.value AS item_type,
	sl.name AS shelving_location,
	p.id AS patron_id,
	g.name AS profile_group,
	dem.general_division AS demographic_general_division,
	circ.id AS id,
	cn.id AS call_number,
	cn.label AS call_number_label,
	call_number_dewey(cn.label) AS dewey,
	CASE
		WHEN call_number_dewey(cn.label) ~  E'^[0-9.]+$'
			THEN
				btrim(
					to_char(
						10 * floor((call_number_dewey(cn.label)::float) / 10), '000'
					)
				)
		ELSE NULL
	END AS dewey_block_tens,
	CASE
		WHEN call_number_dewey(cn.label) ~  E'^[0-9.]+$'
			THEN
				btrim(
					to_char(
						100 * floor((call_number_dewey(cn.label)::float) / 100), '000'
					)
				)
		ELSE NULL
	END AS dewey_block_hundreds,
	CASE
		WHEN call_number_dewey(cn.label) ~  E'^[0-9.]+$'
			THEN
				btrim(
					to_char(
						10 * floor((call_number_dewey(cn.label)::float) / 10), '000'
					)
				)
				|| '-' ||
				btrim(
					to_char(
						10 * floor((call_number_dewey(cn.label)::float) / 10) + 9, '000'
					)
				)
		ELSE NULL
	END AS dewey_range_tens,
	CASE
		WHEN call_number_dewey(cn.label) ~  E'^[0-9.]+$'
			THEN
				btrim(
					to_char(
						100 * floor((call_number_dewey(cn.label)::float) / 100), '000'
					)
				)
				|| '-' ||
				btrim(
					to_char(
						100 * floor((call_number_dewey(cn.label)::float) / 100) + 99, '000'
					)
				)
		ELSE NULL
	END AS dewey_range_hundreds,
	hl.id AS patron_home_lib,
	hl.shortname AS patron_home_lib_shortname,
	paddr.county AS patron_county,
	paddr.city AS patron_city,
	paddr.post_code AS patron_zip,
	sc1.stat_cat_entry AS stat_cat_1,
	sc2.stat_cat_entry AS stat_cat_2,
	sce1.value AS stat_cat_1_value,
	sce2.value AS stat_cat_2_value
  FROM	action.circulation circ
	JOIN reporter.circ_type circ_type ON (circ.id = circ_type.id)
	JOIN asset.copy cp ON (cp.id = circ.target_copy)
	JOIN asset.copy_location sl ON (cp.location = sl.id)
	JOIN asset.call_number cn ON (cp.call_number = cn.id)
	JOIN actor.org_unit ol ON (cn.owning_lib = ol.id)
	JOIN metabib.rec_descriptor rd ON (rd.record = cn.record)
	JOIN actor.org_unit cl ON (circ.circ_lib = cl.id)
	JOIN actor.usr p ON (p.id = circ.usr)
	JOIN actor.org_unit hl ON (p.home_ou = hl.id)
	JOIN permission.grp_tree g ON (p.profile = g.id)
	JOIN reporter.demographic dem ON (dem.id = p.id)
	JOIN actor.usr_address paddr ON (paddr.id = p.billing_address)
	LEFT JOIN config.language_map lm ON (rd.item_lang = lm.code)
	LEFT JOIN config.lit_form_map lfm ON (rd.lit_form = lfm.code)
	LEFT JOIN config.item_form_map ifm ON (rd.item_form = ifm.code)
	LEFT JOIN config.item_type_map itm ON (rd.item_type = itm.code)
	LEFT JOIN asset.stat_cat_entry_copy_map sc1 ON (sc1.owning_copy = cp.id AND sc1.stat_cat = 1)
	LEFT JOIN asset.stat_cat_entry sce1 ON (sce1.id = sc1.stat_cat_entry)
	LEFT JOIN asset.stat_cat_entry_copy_map sc2 ON (sc2.owning_copy = cp.id AND sc2.stat_cat = 2)
	LEFT JOIN asset.stat_cat_entry sce2 ON (sce2.id = sc2.stat_cat_entry);

CREATE OR REPLACE VIEW reporter.legacy_cat1 AS
SELECT	id,
	owner,
	value
  FROM	asset.stat_cat_entry
  WHERE	stat_cat = 1;

CREATE OR REPLACE VIEW reporter.legacy_cat2 AS
SELECT	id,
	owner,
	value
  FROM	asset.stat_cat_entry
  WHERE	stat_cat = 2;


CREATE OR REPLACE VIEW reporter.classic_current_billing_summary AS
SELECT	x.id AS id,
	x.usr AS usr,
	bl.shortname AS billing_location_shortname,
	bl.name AS billing_location_name,
	x.billing_location AS billing_location,
	c.barcode AS barcode,
	u.home_ou AS usr_home_ou,
	ul.shortname AS usr_home_ou_shortname,
	ul.name AS usr_home_ou_name,
	x.xact_start AS xact_start,
	x.xact_finish AS xact_finish,
	x.xact_type AS xact_type,
	x.total_paid AS total_paid,
	x.total_owed AS total_owed,
	x.balance_owed AS balance_owed,
	x.last_payment_ts AS last_payment_ts,
	x.last_payment_note AS last_payment_note,
	x.last_payment_type AS last_payment_type,
	x.last_billing_ts AS last_billing_ts,
	x.last_billing_note AS last_billing_note,
	x.last_billing_type AS last_billing_type,
	paddr.county AS patron_county,
	paddr.city AS patron_city,
	paddr.post_code AS patron_zip,
	g.name AS profile_group,
	dem.general_division AS demographic_general_division
  FROM	money.open_billable_xact_summary x
	JOIN actor.org_unit bl ON (x.billing_location = bl.id)
	JOIN actor.usr u ON (u.id = x.usr)
	JOIN actor.org_unit ul ON (u.home_ou = ul.id)
	JOIN actor.card c ON (u.card = c.id)
	JOIN permission.grp_tree g ON (u.profile = g.id)
	JOIN reporter.demographic dem ON (dem.id = u.id)
	JOIN actor.usr_address paddr ON (paddr.id = u.billing_address);


COMMIT;


