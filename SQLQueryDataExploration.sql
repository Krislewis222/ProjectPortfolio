-- Cleaning the data

-- Viewing table

SELECT*
FROM ProjectPortfolio..NashvilleHousing


-- Standardized date format

SELECT SaleDate, CONVERT(Date, SaleDate)
FROM ProjectPortfolio..NashvilleHousing

ALTER TABLE ProjectPortfolio..NashvilleHousing
ADD SaleDateConverted Date;

UPDATE ProjectPortfolio..NashvilleHousing
SET SaleDateConverted = CONVERT(Date, SaleDate)

SELECT SaleDateConverted, CONVERT(Date, SaleDate)
FROM ProjectPortfolio..NashvilleHousing



-- Populate Property Address Data

SELECT *
FROM ProjectPortfolio..NashvilleHousing
WHERE PropertyAddress is null


SELECT a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress, ISNULL( a.PropertyAddress, b.PropertyAddress)
FROM ProjectPortfolio..NashvilleHousing a
JOIN ProjectPortfolio..NashvilleHousing b
ON a.ParcelID =b.ParcelID
AND a.[UniqueID ]<> b.[UniqueID ]
WHERE a.PropertyAddress is null

UPDATE a
SET PropertyAddress = ISNULL( a.PropertyAddress, b.PropertyAddress)
FROM ProjectPortfolio..NashvilleHousing a
JOIN ProjectPortfolio..NashvilleHousing b
ON a.ParcelID =b.ParcelID
AND a.[UniqueID ]<> b.[UniqueID ]
WHERE a.PropertyAddress is null


--Breaking Address into individual columns (address, city, state)

SELECT PropertyAddress
FROM ProjectPortfolio..NashvilleHousing


SELECT 
    SUBSTRING(PropertyAddress, 1, CASE WHEN CHARINDEX(',', PropertyAddress) > 0 THEN CHARINDEX(',', PropertyAddress) - 1 ELSE LEN(PropertyAddress) END) as Address1,
    SUBSTRING(PropertyAddress, CASE WHEN CHARINDEX(',', PropertyAddress) > 0 THEN CHARINDEX(',', PropertyAddress) + 1 ELSE 1 END, LEN(PropertyAddress)) as Address2
FROM ProjectPortfolio..NashvilleHousing


ALTER TABLE ProjectPortfolio..NashvilleHousing
ADD PropertySplitAddress NVARCHAR(255);

UPDATE ProjectPortfolio..NashvilleHousing
SET PropertySplitAddress = SUBSTRING(PropertyAddress, 1, CASE WHEN CHARINDEX(',', PropertyAddress) > 0 THEN CHARINDEX(',', PropertyAddress) - 1 ELSE LEN(PropertyAddress) END)


ALTER TABLE ProjectPortfolio..NashvilleHousing
ADD PropertySplitCity NVARCHAR(255);

UPDATE ProjectPortfolio..NashvilleHousing
SET PropertySplitCity = SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) +1, LEN(PropertyAddress))


SELECT *
FROM ProjectPortfolio..NashvilleHousing


--

SELECT OwnerAddress
FROM ProjectPortfolio..NashvilleHousing

SELECT
PARSENAME(REPLACE(OwnerAddress, ',','.'),3)
,PARSENAME(REPLACE(OwnerAddress, ',','.'),2)
,PARSENAME(REPLACE(OwnerAddress, ',','.'),1)
FROM ProjectPortfolio..NashvilleHousing

ALTER TABLE ProjectPortfolio..NashvilleHousing
ADD OwnerSplitAddress NVARCHAR(255);

UPDATE ProjectPortfolio..NashvilleHousing
SET OwnerSplitAddress = PARSENAME(REPLACE(OwnerAddress, ',','.'),3)

ALTER TABLE ProjectPortfolio..NashvilleHousing
ADD OwnerSplitCity NVARCHAR(255);

UPDATE ProjectPortfolio..NashvilleHousing
SET OwnerSplitCity = PARSENAME(REPLACE(OwnerAddress, ',','.'),2)

ALTER TABLE ProjectPortfolio..NashvilleHousing
ADD OwnerSplitState NVARCHAR(255);

UPDATE ProjectPortfolio..NashvilleHousing
SET OwnerSplitState = PARSENAME(REPLACE(OwnerAddress, ',','.'),1)

SELECT *
FROM ProjectPortfolio..NashvilleHousing



--Change Y and N to yes and no

SELECT DISTINCT(SoldAsVacant), Count(SoldAsVacant)
FROM ProjectPortfolio..NashvilleHousing
GROUP BY SoldAsVacant
ORDER BY 2


SELECT SoldAsVacant
, CASE When SoldAsVacant = 'Y' THEN 'Yes'
	When SoldAsVacant = 'N' THEN 'No'
	ELSE SoldAsVacant
	END 
FROM ProjectPortfolio..NashvilleHousing


UPDATE ProjectPortfolio..NashvilleHousing
SET SoldAsVacant= CASE When SoldAsVacant = 'Y' THEN 'Yes'
	When SoldAsVacant = 'N' THEN 'No'
	ELSE SoldAsVacant
	END 

UPDATE ProjectPortfolio..NashvilleHousing
SET SoldAsVacant= CASE When SoldAsVacant = 'YES' THEN 'Yes'
	When SoldAsVacant = 'NO' THEN 'No'
	ELSE SoldAsVacant
	END 

-- Remove Duplicates

WITH RowNumCTE AS(
SELECT *,
	ROW_NUMBER() OVER(
	PARTITION BY ParcelID,
				PropertyAddress,
				SalePrice,
				SaleDate,
				LegalReference
				ORDER BY
					UniqueID
					) row_num
FROM ProjectPortfolio..NashvilleHousing

)
DELETE
FROM RowNumCTE
WHERE row_num >1


-- Delete Unused Columns

SELECT *
FROM ProjectPortfolio..NashvilleHousing

ALTER TABLE ProjectPortfolio..NashvilleHousing
DROP COLUMN OwnerAddress, TaxDistrict, PropertyAddress
