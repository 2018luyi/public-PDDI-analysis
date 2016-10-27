DROP TABLE IF EXISTS Drug_Class_Interaction;

# Temporary table to include different drugs belonging to drug groups in the drug interaction table
CREATE TABLE Drug_Class_Interaction AS (
SELECT i.Drug_Interaction_ID,
	   i.Drug_1_Name,
       COALESCE(i.Drug_1_RxCUI,g.RxNorm) AS drug_1_rxcui,
       i.Drug_1_Class_Name,
       i.Drug_1_Code,
       i.Drug_2_Name,
       COALESCE(i.Drug_2_RxCUI,h.RxNorm) AS drug_2_rxcui,
       i.Drug_2_Class_Name,
       i.Drug_2_Code,
	   g.Drug_Name AS Drug_Name_1,
       i.Drug_1_RxCUI AS Drug_1_RxNorm,
       g.RxNorm AS Drug_1_RxNorm_Group,
       g.Class_Code AS Class_Code_1,
       h.Drug_Name AS Drug_Name_2,
       i.Drug_2_RxCUI AS Drug_2_RxNorm,
       h.RxNorm AS Drug_2_RxNorm_Group,
       h.Class_Code AS Class_Code_2
FROM Drug_Interaction i
LEFT JOIN Drug_Group g
ON (i.Drug_1_Code = TRIM(TRAILING '\r' FROM g.Class_Code))
LEFT JOIN Drug_Group h
ON (i.Drug_2_Code = TRIM(TRAILING '\r' FROM h.Class_Code))
WHERE COALESCE(i.Drug_1_RxCUI,g.RxNorm) != COALESCE(i.Drug_2_RxCUI,h.RxNorm)
GROUP BY COALESCE(i.Drug_1_RxCUI,g.RxNorm), COALESCE(i.Drug_2_RxCUI,h.RxNorm));

# Intersect of WorldVista and NDF-RT datasets

SELECT *, COUNT(*) FROM (
	SELECT drug_1_rxcui,
		   drug_2_rxcui
	FROM NDF_RT_INTERACTION
	WHERE drug_1_rxcui is not null
	AND drug_2_rxcui is not null
    GROUP BY drug_1_rxcui, drug_2_rxcui
	UNION ALL
	SELECT drug_1_rxcui, drug_2_rxcui
	FROM Drug_Class_Interaction
	WHERE drug_1_rxcui is not null 
	AND drug_2_rxcui is not null
) AS all_pddi 
WHERE drug_1_rxcui != drug_2_rxcui 
GROUP BY drug_1_rxcui, drug_2_rxcui
HAVING COUNT(*) > 1
ORDER BY COUNT(*) DESC;

# Set difference of PDDI's that are only in the NDF-RT data set.

SELECT * FROM NDF_RT_INTERACTION n
LEFT JOIN(
	SELECT * FROM (
		SELECT drug_1_rxcui,
			   drug_2_rxcui
		FROM NDF_RT_INTERACTION
		WHERE drug_1_rxcui is not null
		AND drug_2_rxcui is not null
        GROUP BY drug_1_rxcui, drug_2_rxcui
		UNION ALL
		SELECT drug_1_rxcui, drug_2_rxcui
		FROM Drug_Class_Interaction
		WHERE drug_1_rxcui is not null 
		AND drug_2_rxcui is not null
	) AS all_pddi 
	WHERE drug_1_rxcui != drug_2_rxcui 
	GROUP BY drug_1_rxcui, drug_2_rxcui
	HAVING COUNT(*) > 1
) o 
ON o.drug_1_rxcui = n.drug_1_rxcui
AND o.drug_2_rxcui = n.drug_2_rxcui
WHERE o.drug_1_rxcui is null
AND o.drug_2_rxcui is null
AND n.drug_1_rxcui is not null
AND n.drug_2_rxcui is not null
GROUP BY n.drug_1_rxcui, n.drug_2_rxcui;

# Set difference of PDDI's that are only in the WorldVista data set.

SELECT * FROM Drug_Class_Interaction w
LEFT JOIN(
	SELECT * FROM (
		SELECT drug_1_rxcui,
			   drug_2_rxcui
		FROM NDF_RT_INTERACTION
		WHERE drug_1_rxcui is not null
		AND drug_2_rxcui is not null
        GROUP BY drug_1_rxcui, drug_2_rxcui
		UNION ALL
		SELECT drug_1_rxcui, drug_2_rxcui
		FROM Drug_Class_Interaction
		WHERE drug_1_rxcui is not null 
		AND drug_2_rxcui is not null
	) AS all_pddi 
	WHERE drug_1_rxcui != drug_2_rxcui 
	GROUP BY drug_1_rxcui, drug_2_rxcui
	HAVING COUNT(*) > 1
) o 
ON o.drug_1_rxcui = w.drug_1_rxcui
AND o.drug_2_rxcui = w.drug_2_rxcui
WHERE o.drug_1_rxcui is null
AND o.drug_2_rxcui is null
AND w.drug_1_rxcui is not null
AND w.drug_2_rxcui is not null
GROUP BY w.drug_1_rxcui, w.drug_2_rxcui;
