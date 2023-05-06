--создание view
CREATE OR REPLACE VIEW my_view AS
SELECT p.name, p.surname, ct.name as contact_type, c.value
FROM contacts AS c
JOIN contact_type AS ct ON c.contact_type_id = ct.id
JOIN persons AS p ON c.person_id = p.id

--тригерная функция для вставки
CREATE OR REPLACE FUNCTION trigger_function_insert()
RETURNS trigger AS
$$
BEGIN
	--new: name, surname, contact_type, value
	--если нет человека с ФИ - вставляем добавляем запись в persons
	IF NOT EXISTS (SELECT p.name, p.surname FROM persons AS p WHERE p.name = new.name AND p.surname = new.surname) 
	THEN 
		INSERT INTO persons VALUES(DEFAULT, new.name, new.surname);
	END IF;
	--если нет такого типа контакта, то добавляем запись в contact_type
	IF NOT EXISTS (SELECT ct.name FROM contact_type AS ct WHERE ct.name = new.contact_type) 
	THEN
		INSERT INTO contact_type VALUES(DEFAULT, new.contact_type); 
	END IF;
	--данные о типе контакта и человеке уже гарантированно будут. Добавляем запись в contacts, с совпадающими айдишниками в соотв. таблицах	
	IF NOT EXISTS (SELECT c.value FROM contacts AS c WHERE c.value = new.value) 
	THEN
		INSERT INTO contacts VALUES(
			DEFAULT,
			(SELECT p.id FROM persons AS p WHERE p.name = new.name AND p.surname = new.surname),
			(SELECT ct.id FROM contact_type AS ct WHERE ct.name = new.contact_type),
			new.value
		);
	END IF;
	RETURN NULL;
END;
$$ LANGUAGE plpgsql;

--тригерная функция для обновления
CREATE OR REPLACE FUNCTION trigger_function_update()
RETURNS trigger AS
$$
BEGIN
	update persons
	set name = new.name, surname = new.surname 
	where name = old.name and name = old.surname;
	
	UPDATE contact_type
	SET name = new.contact_type
	WHERE name = old.contact_type;
	
	UPDATE contacts
	SET value = new.value
	WHERE value = old.value 
	AND (SELECT p.id FROM persons AS p WHERE p.name = new.name AND p.surname = new.surname) = person_id
	AND (SELECT ct.id FROM contact_type AS ct WHERE ct.name = new.contact_type) = contact_type_id;
	
	RETURN NULL;
END;
$$ LANGUAGE plpgsql;

--тригерная функция для удаления
CREATE OR REPLACE FUNCTION trigger_function_delete()
RETURNS trigger AS
$$
DECLARE

BEGIN
	DELETE FROM contacts
	where person_id = (SELECT p.id FROM persons AS p WHERE p.name = OLD.name AND p.surname = OLD.surname) 
	AND contact_type_id = (SELECT ct.id FROM contact_type AS ct WHERE ct.name = OLD.contact_type)
	AND value = OLD.value;
	
	RETURN NULL;
END;
$$ LANGUAGE plpgsql;

--тригер вставки
CREATE TRIGGER view_insert
    INSTEAD OF INSERT ON my_view
    FOR EACH ROW
    EXECUTE FUNCTION trigger_function_insert();
	
--тригер обновления
CREATE TRIGGER view_update
    INSTEAD OF UPDATE ON my_view
    FOR EACH ROW
    EXECUTE FUNCTION trigger_function_update();

--тригер удаления
CREATE TRIGGER view_delete
    INSTEAD OF DELETE ON my_view
    FOR EACH ROW
    EXECUTE FUNCTION trigger_function_delete();

insert into my_view values('testname', 'testsurname', 'icq', '64323');

update my_view set contact_type = 'skype' where contact_type = 'discord'

delete from my_view where name = 'testname' and surname = 'testsurname'

insert into my_view values('test2', 'test2', 'discord', 'test2discord'), 
						  ('test3', 'test3', 'phone_number', '89996665423'),
						  ('test3', 'test3', 'address', 'Lenina-70');
						  
delete from my_view where surname = 'test2' or surname = 'test3'

update my_view set contact_type = 'gggg' where contact_type = 'hhhh'

update my_view 
set name = format('%s_changed', name)
where surname like 'test%'

insert into my_view values('Andrey', 'Semenov', 'index', '614066');
