--Part 2a (Question 1)

--Using CTE, this first query is expected to return all successful transactions
with successful_transactions as (
	select *  
	from  alt_school.events 
	where 
		event_data  @> '{"status": "success"}'),
		
--This query pulls all items added to cart in which the transactions were successful
added_items as ( 
	select e.* 
	from  	alt_school.events e 
		right join 
			successful_transactions b
		on e.customer_id = b.customer_id
	where (
		e.event_data ->> 'event_type' = 'add_to_cart' )),

--This query pulls all items removed from cart in which the transactions were successful
removed_items as ( 
	select e.* 
	from  	alt_school.events e 
		right join 
			successful_transactions b
	on e.customer_id = b.customer_id
	where (
		e.event_data ->> 'event_type' = 'remove_from_cart' )),

--This query pulls only items that were successfully checked out by taking out items added but were later removed
checked_out_items as (
	select * 
	from added_items 
	where 
		not exists (
			select *
			from removed_items
			where 
				added_items.Customer_id = removed_items.customer_id and 
				added_items.event_data ->> 'item_id' = removed_items.event_data ->> 'item_id'
))

--This count the number of successful transaction for each item
	select 
		p.id, 
		p.name, 
		count(l.item_id)  as num_of_time_in_successful_transactions  
	from 	checked_out_items 
	
		left join 
			alt_school.orders  o 
			on checked_out_items.customer_id = o.customer_id 
			
		join alt_school.line_items l
			on o.order_id  = l.order_id and 
				checked_out_items.event_data ->> 'item_id' = cast(l.item_id as varchar)
				
		join alt_school.products p 
			on l.item_id = p.id 
			
	group by p.id, p.name
	order by 3 desc
	limit 1;





--Part 2a (Question 2)

--Using CTE, this first query is expected to return all successful transactions
with successful_transactions as (
	select *  
		from  alt_school.events 
	where 
		event_data  @> '{"status": "success"}'),
		
--This query pulls all items added to cart in which the transactions were successful
added_items as ( 
	select e.* 
	from  	alt_school.events e 
		right join 
			successful_transactions b
		on e.customer_id = b.customer_id
	where (
		e.event_data ->> 'event_type' = 'add_to_cart' )),

--This query pulls all items removed from cart in which the transactions were successful
removed_items as ( 
	select e.* 
	from  	alt_school.events e 
		right join 
			successful_transactions b
		on e.customer_id = b.customer_id
	where (
		e.event_data ->> 'event_type' = 'remove_from_cart' )),

--This query pulls only items that were successfully checked out by taking out items added but were later removed
checked_out_items as (
	select * 
	from added_items
	where 
		not exists (
			select *
			from removed_items
			where 	added_items.Customer_id = removed_items.customer_id and 
					added_items.event_data ->> 'item_id' = removed_items.event_data ->> 'item_id'
))

--This extracts the quantity value in the event_data to calculate the total_spend value by customer and location
select 
	a.customer_id, 
	c.location, 
	SUM(cast(a.event_data ->> 'quantity' as INT) * p.price)  as total_spend 
from 	checked_out_items a 
	left join 
		alt_school.products p 
	on a.event_data ->> 'item_id' = cast(p.id as varchar)
	left join alt_school.customers c 
	on a.customer_id = c.customer_id
group by 
	a.customer_id, 
	c.location
order by 3 desc
limit 5;




--Part 2b (Question 1)
--This returns the count of checkouts by location where only successful checkout occurred.
select 
	c."location" , 
	COUNT(e.event_id) as checkout_count 
from  	alt_school.events e 
	left join 
		alt_school.customers c 
	on e.customer_id  = c.customer_id 
where 
	event_data  @> '{"status": "success"}'
group by 
	c."location" 
order by 2 desc
limit 1;




--Part 2b (Question 2)
--This pulls events that includes adding and removing items from cart.
with added_removed_items as (
	select * 
	from alt_school.events e 
	where (
		e.event_data ->> 'event_type' IN ('add_to_cart', 'remove_from_cart') )),
--This pulls only successful transactions from the event table
successful_transactions as (
	select * 
	from  alt_school.events e 
	where (
		e.event_data  @> '{"status": "success"}')),

number_of_events as (
	select 
--count of events by customers for only customers that abandoned their cart
		added_removed_items.customer_id, 
		COUNT(added_removed_items.event_id) as num_events 
	from added_removed_items
	where 
--Here, customers with successful transactions were removed from the list to focus on customers with abandoned transactions
		not exists (
			select *
			from successful_transactions
			where 
				added_removed_items.Customer_id = successful_transactions.customer_id)
	group by 1
)
	select * 
	from number_of_events 
	order by num_events desc;




--Part 2b (Question 3)

--This query pulls transaction that were completed 
with successful_transactions as (
	select 
		*  
	from  alt_school.events 
	where 
		event_data  @> '{"status": "success"}'),
	
--This pulls visit events only by the customers who completed a checkout
visits as ( 
	select 
		e.* 
	from  	alt_school.events e 
		right join 
			successful_transactions b
	on e.customer_id = b.customer_id
	where (
		e.event_data ->> 'event_type' = 'visit' ))
		
--This gives an average of visit before a successful checkout was made and rounded to 2 decimal place.
	select 
		round(
			COUNT(customer_id) *1.00 /  
				count(distinct customer_id),2) as average_visits  from visits



