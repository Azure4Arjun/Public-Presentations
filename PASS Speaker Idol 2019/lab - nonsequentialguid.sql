use master
go
CREATE DATABASE [make_ints_not_guids]
 CONTAINMENT = NONE
 ON  PRIMARY 
( NAME = N'make_ints_not_guids', FILENAME = N'f:\DATA\make_ints_not_guids.mdf' , SIZE = 800192KB , FILEGROWTH = 65536KB )
 LOG ON 
( NAME = N'make_ints_not_guids_log', FILENAME = N'f:\DATA\make_ints_not_guids_log.ldf' , SIZE = 8192KB , FILEGROWTH = 65536KB )
GO 
ALTER DATABASE [make_ints_not_guids] SET AUTO_UPDATE_STATISTICS ON 
GO
use [make_ints_not_guids]
go
--drop table if exists dbo.nonsequentialguid
go
create table dbo.nonsequentialguid
(id uniqueidentifier not null CONSTRAINT DF_nonseq_id DEFAULT newsequentialid()
, whenobserved datetimeoffset(2)  not null CONSTRAINT DF_nonseq_when DEFAULT sysdatetimeoffset() 
, whatever char(1) not null
, constraint pk_nonseq primary key (id) --WITH (OPTIMIZE_FOR_SEQUENTIAL_KEY = on)--SQL 2019+
) 
go

--Run the below command after reboots, failovers, etc. You will eventually start writing nonsequential "sequential" guids.
insert into dbo.nonsequentialguid (whatever) values ('a')
go

--Check for nonsequential "sequential" GUIDs. All will trigger if it happens.
select n1.id, n1.whenobserved, n2.id, n2.whenobserved  from nonsequentialguid n1
, nonsequentialguid n2
where n1.id > n2.id and n1.whenobserved < n2.whenobserved -- when an id is greater than another record, but its when is less than the other record's when. It's happened.
order by n1.id, n2.id

select * from (
select id, whenobserved, rank_when = rank () over (order by whenobserved), rank_id = rank() over (order by id) from nonsequentialguid
) x where rank_when <> rank_id -- when rank of id <> the rank of when, they're out of order. It's happened.S
order by rank_id, rank_when

select id, whenobserved 
 from nonsequentialguid n1
 order by id asc -- when first records in this sort order will have been inserted after later records, it's happened.


 --Conditions that trigger a nonsequential "sequential" guid
 --- Failover to another machine may trigger in FC or AG
 --- Upgrade or Migrate the database to new hardware, new platform
 --- Re-image an Azure VM with ephemeral OS may trigger
 --- Since the C++ function UuidCreateSequential is based on the MAC address of a machine's Ethernet card, changing or replacing the network interface may trigger,
 ------ You cannot specify the MAC address of a new Azure network interface to prevent this on a new machine!
 ------ more info: https://docs.microsoft.com/en-us/windows/win32/api/rpcdce/nf-rpcdce-uuidcreatesequential?redirectedfrom=MSDN
 ------ "Therefore you should never use this UUID to identify an object that is not strictly local to your computer."

