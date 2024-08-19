select  * from sales_data_sample


--Checing unique values

select distinct STATUS from sales_data_sample--Nice oneto plot
select distinct YEAR_ID from sales_data_sample
select distinct  PRODUCTLINE from sales_data_sample--Nice to plot
select distinct COUNTRY from sales_data_sample--Nice to plot
select distinct DEALSIZE from sales_data_sample--Nice to plot
select distinct TERRITORY from sales_data_sample--Nice to plot


--Analysis 
--start by grouping sales by productline

select PRODUCTLINE ,sum(SALES) Revenue -->Hasýlat demektir
from sales_data_sample 
group by PRODUCTLINE
order by 2 desc

select YEAR_ID ,sum(SALES) Revenue -->Hasýlat demektir
from sales_data_sample 
group by YEAR_ID
order by 2 desc

select distinct MONTH_ID from sales_data_sample
where YEAR_ID=2005

select DEALSIZE ,sum(SALES) Revenue -->Hasýlat demektir
from sales_data_sample 
group by DEALSIZE
order by 2 desc

--What was the  best month for sales in a spesicific year?

select MONTH_ID ,sum(SALES) Revenue,count(ORDERNUMBER) Frequency
from sales_data_sample 
where YEAR_ID=2004
group by MONTH_ID
order by 2 desc

select MONTH_ID ,PRODUCTLINE,sum(SALES) Revenue,count(ORDERNUMBER) Frequency
from sales_data_sample 
where YEAR_ID=2004 AND MONTH_ID=11
group by MONTH_ID,PRODUCTLINE
order by Revenue desc

--who is the our best custemor(RFM)

	DROP TABLE IF EXISTS #rfm;

WITH rfm AS (
    SELECT 
        CUSTOMERNAME,
        SUM(sales) AS Monetary_Value,
        AVG(sales) AS AvgMonetary_Value,
        COUNT(ORDERNUMBER) AS Frequency,
        MAX(ORDERDATE) AS Last_Order_Date,
        (SELECT MAX(ORDERDATE) FROM sales_data_sample) AS Max_Order_Date,
        DATEDIFF(DAY, MAX(ORDERDATE), (SELECT MAX(ORDERDATE) FROM sales_data_sample)) AS Recency
    FROM 
        sales_data_sample 
    GROUP BY 
        CUSTOMERNAME
),

rfm_calc AS (
    SELECT 
        r.*,
        NTILE(4) OVER (ORDER BY Recency DESC) AS rfm_recency,
        NTILE(4) OVER (ORDER BY Frequency) AS rfm_frequency,
        NTILE(4) OVER (ORDER BY AvgMonetary_Value) AS rfm_monetary
    FROM 
        rfm r
)
SELECT 
    c.*,  
    (rfm_recency + rfm_frequency + rfm_monetary) AS rfm_cell,
    (CAST(rfm_frequency AS VARCHAR) + CAST(rfm_recency AS VARCHAR) + CAST(rfm_monetary AS VARCHAR)) AS rfm_cellstring
INTO 
    #rfm
FROM 
    rfm_calc c;

	select CUSTOMERNAME , rfm_recency, rfm_frequency, rfm_monetary,
	case 
		when rfm_cellstring in (111, 112 , 121, 122, 123, 132, 211, 212, 114, 141) then 'lost_customers'  --lost customers
		when rfm_cellstring in (133, 134, 143, 244, 334, 343, 344, 144) then 'slipping away, cannot lose' -- (Big spenders who haven’t purchased lately) slipping away
		when rfm_cellstring in (311, 411, 331) then 'new customers'
		when rfm_cellstring in (222, 223, 233, 322) then 'potential churners'
		when rfm_cellstring in (323, 333,321, 422, 332, 432) then 'active' --(Customers who buy often & recently, but at low price points)
		when rfm_cellstring in (433, 434, 443, 444) then 'loyal'
	end rfm_segment

from #rfm
select* from #rfm

--What products are most often sold together? 

SELECT DISTINCT 
    s.ORDERNUMBER, 
    STUFF(
        (
            SELECT ',' + p.PRODUCTCODE
            FROM sales_data_sample p
            WHERE p.ORDERNUMBER = s.ORDERNUMBER
            FOR XML PATH ('')
        ), 
        1, 1, ''
    ) AS ProductCodes
FROM 
    sales_data_sample s
WHERE 
    s.ORDERNUMBER IN 
    (
        SELECT ORDERNUMBER
        FROM 
        (
            SELECT ORDERNUMBER, COUNT(*) AS rn
            FROM sales_data_sample
            WHERE STATUS = 'Shipped'
            GROUP BY ORDERNUMBER
        ) m
        WHERE rn = 3
    )
ORDER BY 
    ProductCodes DESC;

---EXTRAs----
--What city has the highest number of sales in a specific country
select CITY, sum (sales) Revenue
from  sales_data_sample 
where country = 'UK'
group by CITY
order by 2 desc



---What is the best product in United States?
select country, YEAR_ID, PRODUCTLINE, sum(sales) Revenue
from    sales_data_sample 

where country = 'USA'
group by  country, YEAR_ID, PRODUCTLINE
order by 4 desc
