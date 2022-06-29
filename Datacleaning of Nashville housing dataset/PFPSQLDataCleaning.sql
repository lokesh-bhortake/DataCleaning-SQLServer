/*
	Cleaning data with SQL
*/


SELECT *
FROM PFPDataCleaning.dbo.NashVilleHousing



-- Standardize date format 
-- 2013-04-09 00:00:00.000 We just want to extract date from it 
ALTER TABLE NashvilleHousing
ADD SaleDateConverted DATE;

Update NashvilleHousing
SET SaleDateConverted = CONVERT(DATE, SaleDate)



-- Populate Property address data
-- We found that where the parcel id is same, the property id is also same 
-- so we can fill up the null values of property address if the address is null and parcel id is same
-- Forming and checking the query
SELECT a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress, ISNULL(a.PropertyAddress, b.PropertyAddress)
FROM PFPDataCleaning.dbo.NashVilleHousing AS a
JOIN PFPDataCleaning.dbo.NashVilleHousing AS b
	ON a.ParcelID = b.ParcelID
	AND a.[UniqueID ] <> b.[UniqueID ]
WHERE a.PropertyAddress IS NULL

-- Updating the dataset
UPDATE a 
SET PropertyAddress = ISNULL(a.PropertyAddress, b.PropertyAddress)
FROM PFPDataCleaning.dbo.NashVilleHousing AS a
JOIN PFPDataCleaning.dbo.NashVilleHousing AS b
	ON a.ParcelID = b.ParcelID
	AND a.[UniqueID ] <> b.[UniqueID ]
WHERE a.PropertyAddress IS NULL



-- Breaking out address into individual columns (Address, City, State)
ALTER TABLE NashvilleHousing
ADD PropertySplitAddress Nvarchar(255), PropertySplitCity Nvarchar(255);

UPDATE NashvilleHousing
SET PropertySplitAddress = SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) - 1),
PropertySplitCity = SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) + 1, LEN(PropertyAddress))


-- For Owner address
ALTER TABLE NashvilleHousing
ADD 
OwnerSplitAddress Nvarchar(255), 
OwnerSplitCity Nvarchar(255), 
OwnerSplitState Nvarchar(20);

UPDATE NashvilleHousing
SET 
OwnerSplitAddress = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3),
OwnerSplitCity = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2),
OwnerSplitState = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1)



-- Change 'Yes' or 'No' to Y or N in SoldAsVacant
-- Testing 
SELECT SoldAsVacant,
CASE 
	WHEN SoldAsVacant = 'Yes'
	THEN REPLACE(SoldAsVacant, 'Yes', 'Y')
	WHEN SoldAsVacant = 'No'
	THEN REPLACE(SoldAsVacant, 'No', 'N')
	ELSE SoldAsVacant
END
FROM PFPDataCleaning.dbo.NashVilleHousing

-- Updating
UPDATE NashVilleHousing
SET SoldAsVacant = 
CASE 
	WHEN SoldAsVacant = 'Yes' THEN 'Y'
	WHEN SoldAsVacant = 'No' THEN 'N'
	ELSE SoldAsVacant
END



-- Removing Duplicates
WITH RowNumCTE AS(
SELECT *,  
ROW_NUMBER() OVER ( PARTITION BY ParcelID,
						PropertyAddress,
						SalePrice,
						SaleDate,
						LegalReference
						ORDER BY UniqueID
					) row_num
FROM PFPDataCleaning.dbo.NashVilleHousing
)
DELETE 
FROM RowNumCTE
WHERE row_num > 1



-- Delete Unused columns 
SELECT *
FROM PFPDataCleaning.dbo.NashVilleHousing

ALTER TABLE PFPDataCleaning.dbo.NashVilleHousing
DROP COLUMN OwnerAddress, TaxDistrict, PropertyAddress, SaleDate


