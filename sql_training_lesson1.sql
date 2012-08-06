drop table countries cascade constraints;
create table countries (
  country_id   char(2),
  country_name varchar2(40),
  constraint country_c_id_pk primary key (country_id)
);
alter table countries add constraint country_id_nn 
    check ("country_id" is not null);
-------------------------------------------------------------------------------
host (sqlldr training/pass control=c:\data\loader.ctl);
-------------------------------------------------------------------------------
drop table tmp_departments cascade constraints;
create table tmp_departments (
  department_name varchar2(30)
);
alter table tmp_departments add constraint tmp_dept_name_nn 
    check ("department_name" is not null);
-------------------------------------------------------------------------------
begin
  for i in (select department_name as name from departments)
  loop
    insert into tmp_departments values (i.name);
  end loop;
end;
/
-------------------------------------------------------------------------------
drop table departments cascade constraints;
create table departments (
  department_id   number(4) not null,
  department_name varchar2(30) not null,
  manager_id      number(6),
  country_id   char(2)
);
alter table departments add constraint dept_id_pk primary key (department_id);
alter table departments add constraint dept_mgr_fk foreign key (manager_id) 
    references employees (employee_id);
alter table departments add constraint emp_country_fk foreign key (country_id) 
    references countries (country_id);
-------------------------------------------------------------------------------
drop sequence country_seq;
drop sequence emp_seq;
create sequence country_seq start with 1;
create sequence emp_seq start with 1;
-------------------------------------------------------------------------------
declare
cur_dep_num number;
matches_num number;
rand_dep varchar2(30);
repeat boolean;
begin
  for i in (select country_id as id from training.countries)
  loop
    select count(*) into cur_dep_num from departments where country_id like i.id;
    while (cur_dep_num < 3) loop
      repeat :=true;
      while (repeat) loop
        select * into rand_dep from
              (select * from tmp_departments order by dbms_random.value)
        where rownum = 1;
        
        select count(*) into matches_num from departments
          where  department_name = rand_dep and country_id = i.id;

        if( matches_num = 0 ) then
          insert into departments values (country_seq.nextval, rand_dep, null, i.id);
          commit;
          repeat := false;
        end if;        
      end loop;
      select count(*) into cur_dep_num from departments where country_id like i.id;
    end loop;
  end loop;
end;
/
-------------------------------------------------------------------------------
drop table tmp_departments cascade constraints;
-------------------------------------------------------------------------------
drop table tmp_employees cascade constraints;
create table tmp_employees (
  first_name varchar2(20) not null,
  last_name varchar2(25) not null
);
-------------------------------------------------------------------------------
begin
  for i in (select first_name fn, last_name ln from employees)
  loop
    insert into tmp_employees values (i.fn, i.ln);
  end loop;
end;
/
-------------------------------------------------------------------------------
drop table employees cascade constraints;
create table EMPLOYEES (
  EMPLOYEE_ID    NUMBER(6) not null,
  FIRST_NAME     VARCHAR2(20),
  LAST_NAME      VARCHAR2(25),
  EMAIL          VARCHAR2(25),
  PHONE_NUMBER   VARCHAR2(20),
  HIRE_DATE      DATE,
  JOB_ID         VARCHAR2(10),
  SALARY         NUMBER(8,2),
  COMMISSION_PCT NUMBER(2,2),
  MANAGER_ID     NUMBER(6),
  DEPARTMENT_ID  NUMBER(4)
);
alter table employees add constraint emp_emp_id_pk primary key (employee_id);
alter table EMPLOYEES add constraint EMP_EMAIL_UK unique (EMAIL);
alter table EMPLOYEES add constraint EMP_DEPT_FK foreign key (DEPARTMENT_ID) references DEPARTMENTS (DEPARTMENT_ID);
alter table EMPLOYEES add constraint EMP_JOB_FK foreign key (JOB_ID) references JOBS (JOB_ID);
alter table EMPLOYEES add constraint EMP_EMAIL_NN check ("EMAIL" IS NOT NULL);
alter table EMPLOYEES add constraint EMP_HIRE_DATE_NN check ("HIRE_DATE" IS NOT NULL);
alter table EMPLOYEES add constraint EMP_JOB_NN check ("JOB_ID" IS NOT NULL);
alter table EMPLOYEES add constraint EMP_LAST_NAME_NN check ("LAST_NAME" IS NOT NULL);
alter table EMPLOYEES add constraint EMP_SALARY_MIN check (salary > 0);
create index EMP_DEPARTMENT_IX on EMPLOYEES (DEPARTMENT_ID);
create index EMP_JOB_IX on EMPLOYEES (JOB_ID);
create index emp_manager_ix on employees (manager_id);
create index emp_name_ix on employees (last_name, first_name);
-------------------------------------------------------------------------------
declare
  fn varchar2(20);
  ln varchar2(25);
  ji varchar2(10);
  curr_id number;
  tm varchar2(20);
begin
  dbms_output.put_line(to_char(sysdate,'hh24:mi:ss'));
  for i in (select department_id as id from departments) loop
    for j in 1..1000 loop
      select first_name into fn from (select first_name from tmp_employees order by dbms_random.value)
      where rownum = 1;
      
      select last_name into ln 
      from (select last_name  from tmp_employees order by dbms_random.value)
      where rownum = 1;
      
      select job_id into ji
      from (select job_id from jobs order by dbms_random.value)
      where rownum = 1;
      
      curr_id := emp_seq.nextval;
      
      insert into employees 
      values(
        curr_id, fn, ln,
        /*e-mail*/
          (select upper(substr(fn, 1, 1)||ln||to_char(curr_id)) from dual),
        /*phone num*/
          (select to_char(department_id)||'-'||
              to_char(trunc(dbms_random.value(0,100)))||'-'||
              to_char(trunc(dbms_random.value(0,100)))
            from departments
            where department_id = i.id
          ),
        /*hire date*/
          (select to_date(sysdate,'dd.mm.yyyy')-trunc(dbms_random.value(0,3650)) from dual),
        /*job_id*/ji,
        /*salary*/
          (trunc(dbms_random.value(
              (select min_salary from jobs where job_id = ji),
              (select max_salary from jobs where job_id = ji)))
          ),
        /*commision pct*/null, /*manger id*/null, /*department id*/i.id
      );
      commit;
    end loop;
  end loop;
  dbms_output.put_line(to_char(sysdate,'hh24:mi:ss'));
end;
/
-------------------------------------------------------------------------------
drop table tmp_employees cascade constraints;
