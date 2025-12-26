create database FedEx;
use FedEx;
select * from orderdata;
select distinct(count(order_id)) from orderdata;
select * from orderdata;
select * from routedata;
select * from shipmentdata;
select distinct(count(shipment_id)) from shipmentdata;

-- Task 1: Data Cleaning & Preparation (10 Marks) 

--     1. Identify and delete duplicate Order_ID or Shipment_ID records.
				SELECT order_id,COUNT(*) AS count_duplicates
				FROM orderdata
				GROUP BY order_id
				HAVING COUNT(*) > 1;

				SELECT shipment_id,COUNT(*) AS count_duplicates
				FROM shipmentdata
				GROUP BY shipment_id
				HAVING COUNT(*) > 1;
                
--    2. Replace null or missing Delay_Hours values in the Shipments Table with the average delay for that Route_ID. 
				SELECT * FROM shipmentdata;
				SELECT route_id FROM shipmentdata WHERE delay_hours IS NULL; /* so ther+e is no null or missing values for route_id*/


--     3. Convert all date columns (Order_Date, Pickup_Date, Delivery_Date) into YYYY-MM-DD HH:MM:SS format using SQL date functions.
                      SELECT * FROM orderdata;
					  describe orderdata;
					  alter table orderdata modify order_date timestamp;
					  describe orderdata;
                      
                      SELECT * FROM shipmentdata;
                      DESCRIBE shipmentdata;
					  ALTER TABLE shipmentdata MODIFY pickup_date TIMESTAMP;
                      DESCRIBE shipmentdata;
                      
                      
                      SELECT * FROM shipmentdata;
                      DESCRIBE shipmentdata;
					  ALTER TABLE shipmentdata MODIFY delivery_date TIMESTAMP;
                      DESCRIBE shipmentdata;
				
--  4. Ensure that no Delivery_Date occurs before Pickup_Date (flag such records).
					SELECT * FROM shipmentdata; 
					SELECT shipment_id,order_id,pickup_date,delivery_date,
					CASE 
					WHEN delivery_date < pickup_date THEN 'INVALID'
					ELSE 'VALID'
					END AS date_status
					FROM shipmentdata;
                      
--   5. Validate referential integrity between Orders, Routes, Warehouses, and Shipments.
						SELECT s.*
						FROM shipmentdata s
						LEFT JOIN orderdata o ON s.order_id = o.order_id
						WHERE o.order_id IS NULL;

						SELECT s.*
						FROM shipmentdata s
						LEFT JOIN routedata r ON s.route_id = r.route_id
						WHERE r.route_id IS NULL;

						SELECT s.*
						FROM shipmentdata s
						LEFT JOIN warehousedata w ON s.warehouse_id = w.warehouse_id
						WHERE w.warehouse_id IS NULL;
                        
                        
-- Task 2: Delivery Delay Analysis (10 Marks)

--       1. Calculate delivery delay (in hours) for each shipment using Delivery_Date – Pickup_Date.

					SELECT * FROM shipmentdata;
					SELECT shipment_id,pickup_date,delivery_date,
					TIMESTAMPDIFF(HOUR, pickup_date, delivery_date) AS delay_in_hours 
					FROM shipmentdata;
                    
    --               // add delay hours into table in shipmentdata table.
                     ALTER TABLE shipmentdata add column delay_in_hours int;
					 UPDATE shipmentdata set delay_in_hours =TIMESTAMPDIFF(HOUR, pickup_date, delivery_date);
                     SELECT * FROM shipmentdata;
                    
--       2. Find the Top 10 delayed routes based on average delay hours.

					SELECT * FROM shipmentdata;
					SELECT route_id, AVG(delay_in_hours) AS average_delay_hours FROM shipmentdata GROUP BY route_id ORDER BY  average_delay_hours DESC LIMIT 10;
                    
--       3. Use SQL window functions to rank shipments by delay within each Warehouse_ID.

					SELECT shipment_id,warehouse_id,delay_hours,
                    RANK() OVER (
                    PARTITION BY warehouse_id 
                    ORDER BY delay_hours DESC
                    ) AS delay_rank
                    FROM shipmentdata 
                    ORDER BY warehouse_id, delay_rank;
                    
--      4. Identify the average delay per Delivery_Type (Express / Standard) to compare service-level efficiency.
 
						 select * from orderdata;
						 SELECT o.delivery_type, AVG(s.delay_in_hours) AS average_delay_hours FROM orderdata o inner join shipmentdata s 
						 on o.route_id = s.route_id
						 GROUP BY delivery_type ORDER BY average_delay_hours desc;
 
 
 -- Task 3: Route Optimization Insights (20 Marks)
 
 --        1.Average transit time (in hours) across all shipments.
 
					select * from routedata;
					select * from shipmentdata;
					SELECT s.shipment_id,r.avg_transit_time_hours FROM shipmentdata s inner join routedata r
					on s.route_id = r.route_id;
 
 --       2. Average delay (in hours) per route. 
 
				  select * from shipmentdata;
				  select distinct(count(route_id)) from shipmentdata;
				  SELECT route_id, avg(delay_in_hours) as avg_delay_hr from shipmentdata group by route_id order by avg_delay_hr desc ;
 
 --     3. Distance-to-time efficiency ratio = Distance_KM / Avg_Transit_Time_Hours.
 
				 select * from routedata;
				 alter table routedata add column d_to_t_efficiency_ration int;
				 update routedata set d_to_t_efficiency_ration = Distance_KM / Avg_Transit_Time_Hours;
                 select * from routedata;
                 
--     4. Identify 3 routes with the worst efficiency ratio (lowest distance-to-time). 

				select route_id,d_to_t_efficiency_ration from routedata order by d_to_t_efficiency_ration limit 3;
 
 --    5. Find routes with >20% of shipments delayed beyond expected transit time.
 select * from shipmentdata;
 select * from routedata;
SELECT s.Route_ID,COUNT(*) AS total_shipments,SUM(CASE WHEN s.Delay_Hours > r.avg_transit_time_hours THEN 1 ELSE 0 END) AS delayed_shipments,
ROUND((SUM(CASE WHEN s.Delay_Hours > r.avg_transit_time_hours THEN 1 ELSE 0 END)/ COUNT(*)) * 100, 2) AS delayed_percentage
FROM shipmentdata s
JOIN routedata r 
ON s.Route_ID = r.Route_ID
GROUP BY s.Route_ID
HAVING (SUM(CASE WHEN s.Delay_Hours > r.avg_transit_time_hours THEN 1 ELSE 0 END)/ COUNT(*)) > 0.20   
ORDER BY delayed_percentage DESC;
 
 
--   Task 4: Warehouse Performance (10 Marks)
 --        1. Find the top 3 warehouses with the highest average delay in shipments dispatched. 
						select * from warehousedata;
						select w.warehouse_id,max(s.delay_in_hours) as highest_delay 
						from warehousedata w 
						inner join shipmentdata s 
						on w.warehouse_id=s.warehouse_id
						group by warehouse_id
						order by highest_delay desc limit 3 ;
                        
--          2. Calculate total shipments vs delayed shipments for each warehouse. 
						select * from shipmentdata;                        
						SELECT warehouse_id,COUNT(*) AS total_shipments,
						SUM(CASE WHEN delay_hours > 0 THEN 1 ELSE 0 END) AS delayed_shipments
						FROM shipmentdata
						GROUP BY warehouse_id
						order by warehouse_id;

 --           3. Use CTEs to identify warehouses where average delay exceeds the global average delay.
	select * from warehousedata;
			WITH global_avg AS (SELECT AVG(Delay_Hours) AS global_delay FROM shipmentdata),warehouse_avg AS 
			(SELECT Warehouse_ID, AVG(Delay_Hours) AS warehouse_delay 
				FROM shipmentdata 
				GROUP BY Warehouse_ID)
			SELECT Warehouse_ID,warehouse_delay,global_delay
			FROM warehouse_avg
			CROSS JOIN global_avg
			WHERE warehouse_delay > global_delay;





--  4. Rank all warehouses based on on-time delivery percentage.
					select * from warehousedata;
					select warehouse_id,count(warehouse_id) from shipmentdata where delay_hours <= 0 group by warehouse_id order by warehouse_id;
					SELECT w.warehouse_id,w.city,
					COUNT(*) AS total_shipments,
					SUM(CASE WHEN s.delay_hours <= 0 THEN 1 ELSE 0 END) AS ontime_shipments,
					ROUND((SUM(CASE WHEN s.delay_hours <= 0 THEN 1 ELSE 0 END) / COUNT(*)) * 100,2) AS ontime_percentage,
					RANK() OVER (ORDER BY (SUM(CASE WHEN s.delay_hours <= 0 THEN 1 ELSE 0 END) / COUNT(*)) DESC) AS warehouse_rank
					FROM shipmentdata s
					JOIN warehousedata w 
					ON s.warehouse_id = w.warehouse_id
					GROUP BY 
					w.warehouse_id,
					w.city
					ORDER BY warehouse_rank;


--    Task 5: Delivery Agent Performance (10 Marks) 
--           1. Rank delivery agents (per route) by on-time delivery percentage.
					select a.agent_id,a.agent_name,
					ROUND((SUM(CASE WHEN s.delay_hours <= 0 THEN 1 ELSE 0 END) / COUNT(*)) * 100,2) AS ontime_percentage,
					RANK() OVER (ORDER BY (SUM(CASE WHEN s.delay_hours <= 0 THEN 1 ELSE 0 END) / COUNT(*)) DESC) AS agent_rank
					FROM shipmentdata s
					JOIN deliveryagentdata a 
					ON s.agent_id = a.agent_id
					GROUP BY a.agent_id,a.agent_name
                    ORDER BY agent_rank;
 
 --           2. Find agents whose on-time % is below 85%.
					SELECT agent_id,COUNT(*),
					SUM(CASE WHEN delay_hours <= 0 THEN 1 ELSE 0 END) AS ontime_shipments,
					ROUND((SUM(CASE WHEN delay_hours <= 0 THEN 1 ELSE 0 END) / COUNT(*)) * 100,2) AS ontime_percentage
					FROM shipmentdata
					GROUP BY agent_id
					HAVING ontime_percentage < 85
					ORDER BY ontime_percentage desc;

-- 	3.Compare the average rating and experience (in years) of the top 5 vs bottom 5 agents using subqueries.
		select * from deliveryagentdata;
		select agent_id,agent_name,avg_rating, experience_years from deliveryagentdata order by avg_rating and experience_years desc limit 5;
		select agent_id,agent_name,avg_rating, experience_years from deliveryagentdata order by avg_rating and experience_years  limit 5;

		select avg(avg_rating) as avg_rating_top5,avg(experience_years) from (select avg_rating, experience_years  from deliveryagentdata order by avg_rating and experience_years desc limit 5) as top5;
		select avg(avg_rating ) as avg_rating_bottom5,avg(experience_years) from (select avg_rating,experience_years from deliveryagentdata order by avg_rating,experience_years  limit 5) as bottom5;
 
 --  4. Suggest training or workload balancing strategies for low-performing agents based on insights. 
         /* Agents with on-time delivery percentage below 85% and high delay hours require targeted improvements. 
           The following strategies are recommended:
                    Provide route optimization and time-management training.
                    Assign fewer and shorter routes temporarily.
                    Pair low performers with senior agents for mentorship.
                    Rebalance workload during peak hours to avoid delivery bottlenecks.
                    Introduce continuous monitoring and feedback sessions to track improvement. */
 
 -- Task 6: Shipment Tracking Analytics (10 Marks)
 --      1. For each shipment, display the latest status (Delivered, In Transit, or Returned) along with the latest Delivery_Date. 
				SELECT s.shipment_id,s.delivery_status AS latest_status,s.delivery_date AS latest_delivery_date
				FROM shipmentdata s
				JOIN (SELECT shipment_id,MAX(delivery_date) AS latest_delivery_date
					FROM shipmentdata
					GROUP BY shipment_id) m
				ON s.shipment_id = m.shipment_id
				AND s.delivery_date = m.latest_delivery_date;

--    2. Identify routes where the majority of shipments are still “In Transit” or “Returned”. 
                   select * from shipmentdata;
                   select * from routedata;
                   select r.route_id,s.shipment_id ,s.delivery_status from shipmentdata s inner join routedata r
                   on r.route_id = s.route_id
                   where s.delivery_status in ("In Transit","Returned");
                   
                   select delivery_status,route_id ,SUM(CASE WHEN delivery_status IN ('In Transit', 'Returned') THEN 1 ELSE 0 END)
                   AS pending_shipments from shipmentdata group by route_id,delivery_status order by pending_shipments desc;
           
--    3. Find the most frequent delay reasons (if available in delay-related columns or flags). 
					select * from shipmentdata;
					select delay_reason, count(delay_reason) as most_frequent_delay_reasons from shipmentdata 
					group by delay_reason order by most_frequent_delay_reasons desc;
                
--     4. Identify orders with exceptionally high delay (>120 hours) to investigate potential bottlenecks.
					select * from orderdata;
					select * from shipmentdata where delay_hours > 120;
                    select  order_id,delay_hours from shipmentdata where delay_hours>120 order by delay_hours desc;
                   
	
-- Task 7: Advanced KPI Reporting (10 Marks) 
--    Create SQL queries to calculate and summarize the following KPIs: 
		--    Average Delivery Delay per Source_Country. 
		--    On-Time Delivery % = (Total On-Time Deliveries / Total Deliveries) * 100. 
		--    Average Delay (in hours) per Route_ID. 
		--    Warehouse Utilization % = (Shipments_Handled / Capacity_per_day) * 100.    
             
			SELECT * FROM routedata;
            SELECT r.source_country,ROUND(AVG(s.delay_hours), 2) AS avg_delay_hours
            FROM shipmentdata s
            inner join routedata r 
            on s.route_id = r.route_id
            GROUP BY source_country
            ORDER BY avg_delay_hours DESC;
             
             
             
			SELECT r.source_country,COUNT(*) AS total_deliveries,SUM(CASE WHEN s.delay_hours <= 0 THEN 1 ELSE 0 END) AS ontime_deliveries,
			ROUND((SUM(CASE WHEN s.delay_hours <= 0 THEN 1 ELSE 0 END) / COUNT(*)) * 100,2) AS ontime_percentage
			FROM shipmentdata s
			inner join routedata r
			on s.route_id=r.route_id
			GROUP BY source_country
            ORDER BY ontime_percentage DESC;
            
            
            SELECT r.route_id,ROUND(AVG(s.delay_hours), 2) AS avg_route_delay
            FROM shipmentdata s
            inner join routedata r 
            on s.route_id=r.route_id
            GROUP BY route_id
            ORDER BY avg_route_delay DESC;
            
            
            
            SELECT w.warehouse_id,w.capacity_per_day,COUNT(s.shipment_id) AS shipments_handled,
            ROUND((COUNT(s.shipment_id) / w.capacity_per_day) * 100,2) AS utilization_percentage
            FROM warehousedata w
            LEFT JOIN shipmentdata s 
            ON w.warehouse_id = s.warehouse_id
            GROUP BY w.warehouse_id, w.capacity_per_day
            ORDER BY utilization_percentage DESC;



             
             
             
             
             