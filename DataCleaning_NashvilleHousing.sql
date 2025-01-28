# Data Cleaning with SQL Queries

SELECT *
FROM nashville_housing_data;

# ----------------------------------------------------------------------------------

# Standardize date format

SELECT SaleDate, STR_TO_DATE(SaleDate, '%m/%d/%Y') AS StandardizedDate
FROM nashville_housing_data;

UPDATE nashville_housing_data
SET SaleDate = STR_TO_DATE(SaleDate, '%m/%d/%Y');

# ----------------------------------------------------------------------------------

# Populate Property Address data
SELECT *
FROM nashville_housing_data
-- WHERE PropertyAddress IS NULL;
ORDER BY ParcelID;

SELECT a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress
FROM nashville_housing_data a
JOIN nashville_housing_data b
	ON a.ParcelID = b.ParcelID
    AND a.UniqueID != b.UniqueID
WHERE a.PropertyAddress IS NULL OR a.PropertyAddress = '';

UPDATE nashville_housing_data a
JOIN nashville_housing_data b
    ON a.ParcelID = b.ParcelID
   AND a.UniqueID != b.UniqueID
SET a.PropertyAddress = b.PropertyAddress
WHERE a.PropertyAddress IS NULL OR a.PropertyAddress = '';

SELECT *
FROM nashville_housing_data
WHERE PropertyAddress IS NULL OR PropertyAddress = '';

# ----------------------------------------------------------------------------------

# Breaking out Property address into individual columns
SELECT PropertyAddress
FROM nashville_housing_data;

SELECT 
SUBSTRING(PropertyAddress,1,LOCATE(',',PropertyAddress) -1) AS Address, 
SUBSTRING(PropertyAddress,LOCATE(',',PropertyAddress) +1, LENGTH(PropertyAddress)) AS City
FROM nashville_housing_data;

ALTER TABLE nashville_housing_data
ADD PropertySplitAddress varchar(255);

UPDATE nashville_housing_data
SET PropertySplitAddress = SUBSTRING(PropertyAddress,1,LOCATE(',',PropertyAddress) -1);

ALTER TABLE nashville_housing_data
ADD PropertySplitCity varchar(255);

UPDATE nashville_housing_data
SET PropertySplitCity = SUBSTRING(PropertyAddress,LOCATE(',',PropertyAddress) +1, LENGTH(PropertyAddress));

SELECT *
FROM nashville_housing_data;

# ----------------------------------------------------------------------------------

# Breaking out Owner address into individual columns

SELECT 
SUBSTRING(OwnerAddress, 1, LOCATE(',', OwnerAddress) - 1) AS Address, 
SUBSTRING(OwnerAddress, LOCATE(',', OwnerAddress) + 2, LOCATE(',', OwnerAddress, LOCATE(',', OwnerAddress) + 1) - LOCATE(',', OwnerAddress) - 2) AS City,
SUBSTRING(OwnerAddress, LOCATE(',', OwnerAddress, LOCATE(',', OwnerAddress) + 1) + 2) AS Prov
FROM nashville_housing_data;

ALTER TABLE nashville_housing_data
ADD OwnerSplitAddress varchar(255);

UPDATE nashville_housing_data
SET OwnerSplitAddress = SUBSTRING(OwnerAddress, 1, LOCATE(',', OwnerAddress) - 1);

ALTER TABLE nashville_housing_data
ADD OwnerSplitCity varchar(255);

UPDATE nashville_housing_data
SET OwnerSplitCity = SUBSTRING(OwnerAddress, LOCATE(',', OwnerAddress) + 2, LOCATE(',', OwnerAddress, LOCATE(',', OwnerAddress) + 1) - LOCATE(',', OwnerAddress) - 2) ;

ALTER TABLE nashville_housing_data
ADD OwnerSplitState varchar(255);

UPDATE nashville_housing_data
SET OwnerSplitState = SUBSTRING(OwnerAddress, LOCATE(',', OwnerAddress, LOCATE(',', OwnerAddress) + 1) + 2);

# ----------------------------------------------------------------------------------

SELECT DISTINCT(SoldAsVacant), Count(SoldAsVacant)
FROM nashville_housing_data
GROUP BY SoldAsVacant
ORDER BY 2;

SELECT SoldAsVacant, 
	CASE WHEN SoldAsVacant = 'Y' THEN 'YES'
		 WHEN SoldAsVacant = 'N' THEN 'NO'
         ELSE SoldAsVacant
         END
FROM nashville_housing_data;

UPDATE nashville_housing_data
SET SoldAsVacant = CASE WHEN SoldAsVacant = 'Y' THEN 'YES'
		 WHEN SoldAsVacant = 'N' THEN 'NO'
         ELSE SoldAsVacant
         END;
         
# ----------------------------------------------------------------------------------

# Remove Duplicates
WITH RowNumCTE AS (
    SELECT 
        UniqueID,
        PropertyAddress, 
        ROW_NUMBER() OVER (
            PARTITION BY ParcelID, PropertyAddress, SalePrice, SaleDate, LegalReference
            ORDER BY UniqueID
        ) AS row_num
    FROM nashville_housing_data
)
-- DELETE n
-- FROM nashville_housing_data n
-- JOIN RowNumCTE cte
--     ON n.UniqueID = cte.UniqueID
-- WHERE cte.row_num > 1;
SELECT *
FROM RowNumCTE
WHERE row_num > 1
ORDER BY PropertyAddress;

# ----------------------------------------------------------------------------------

# Delete unused columns

SELECT *
FROM nashville_housing_data;

ALTER TABLE nashville_housing_data DROP COLUMN OwnerAddress;
ALTER TABLE nashville_housing_data DROP COLUMN TaxDistrict;
ALTER TABLE nashville_housing_data DROP COLUMN PropertyAddress;
ALTER TABLE nashville_housing_data DROP COLUMN SaleDate;



