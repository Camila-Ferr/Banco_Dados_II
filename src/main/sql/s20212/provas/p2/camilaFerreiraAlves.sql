DO $$ BEGIN
    PERFORM drop_functions();
    PERFORM drop_tables();
END $$;

CREATE TABLE Atividade(
    id INT,
    nome VARCHAR);

CREATE TABLE Artista(
    id INT,
    nome VARCHAR,
    rua VARCHAR,
    cidade VARCHAR,
    estado VARCHAR,
    cep VARCHAR,
    atividade INT);

CREATE TABLE Arena(
    id INT,
    nome VARCHAR,
    cidade VARCHAR,
    capacidade INT);

CREATE TABLE Concerto(
    id INT,
    artista INT,
    arena INT,
    inicio TIMESTAMP,
    fim TIMESTAMP,
    preco FLOAT);


INSERT INTO Atividade values (1, 'vocalista');
INSERT INTO Atividade values (2, 'tecladista');
INSERT INTO Atividade values (3, 'baterista');
INSERT INTO Artista values (1, 'Sandy','Rua Peri','RJ','11111111', 1);
INSERT INTO Artista values (3, 'Junior','Pacheco','SP','11111112', 2);
INSERT INTO Artista values (2, 'Tibbi','Niteroi','RJ','11111113', 3);
INSERT INTO Arena values (1, 'Cantareira','Niteroi',100);
INSERT INTO Arena values (2, 'Maracanã', 10000);
INSERT INTO Arena values (3, 'Vivo Rio', 2000);


CREATE OR REPLACE FUNCTION checar() RETURNS TRIGGER AS $$
declare
begin
    
    IF EXISTS (SELECT * FROM Concerto
                WHERE concerto.id != new.id AND
                (concerto.arena = new.arena OR concerto.artista = new.artista) AND
                (concerto.inicio BETWEEN new.inicio AND new.fim or concerto.fim BETWEEN new.inicio and new.fim)) THEN
        raise exception 'O ARTISTA E A ARENA ESTÃO OCUPADOS NESSE HORÁRIO.';
    END IF;

    return NEW;
end;
$$ language plpgsql;




CREATE TRIGGER Checar
AFTER INSERT OR UPDATE ON Concerto FOR EACH ROW
EXECUTE PROCEDURE checar();







CREATE OR REPLACE FUNCTION criaTemporaria() RETURNS TRIGGER AS $$
declare
begin
    create temp table TabelaTemp(id int) on commit drop;
    return null;
end;
$$ language plpgsql;


CREATE TRIGGER CriaTemporaria
BEFORE UPDATE OR DELETE ON Artista FOR EACH STATEMENT
EXECUTE PROCEDURE criaTemporaria();






CREATE OR REPLACE FUNCTION artista() RETURNS TRIGGER AS $$
declare
begin
    INSERT INTO TabelaTemp values(old.atividade);
    return null;
end;
$$ language plpgsql;


CREATE TRIGGER Artista
AFTER UPDATE OR DELETE ON Artista FOR EACH ROW
EXECUTE PROCEDURE artista();




CREATE OR REPLACE FUNCTION checarAt() RETURNS TRIGGER AS $$
declare
    counter int;
    atvd record;
begin
    
    FOR atvd in SELECT DISTINCT * FROM TabelaTemp LOOP

        Select count(*) from Artista WHERE atividade = atvd.id INTO counter;
        IF counter = 0 THEN
            raise exception 'ATIVIDADE SEM ARTISTA!';
        END IF;

    END LOOP;

    return NULL;
end;
$$ language plpgsql;

CREATE TRIGGER ChecarAt
AFTER UPDATE OR DELETE ON Artista FOR EACH STATEMENT
EXECUTE PROCEDURE checarAt();




-- -- Problema da atividade vazia:
--DELETE FROM Artista WHERE id = 1;
-- UPDATE Artista set atividade = 2 WHERE id = 1;


INSERT INTO Concerto values (1, 1, 1, '2022-02-10 00:00:00', '2022-02-10 00:00:10', 1000);
INSERT INTO Concerto values (2, 1, 2, '2022-02-10 00:00:00', '2022-02-10 00:00:05', 1000);
-- INSERT INTO Concerto values (3, 1, 3, '2022-02-10 00:00:00', '2022-02-10 00:00:30', 1000);


-- INSERT INTO Concerto values (1, 1, 1, '2022-02-10 00:00:00', '2022-02-10 00:00:10', 1000);
-- INSERT INTO Concerto values (2, 2, 1, '2022-02-10 00:00:00', '2022-02-10 00:00:05', 1000);
-- INSERT INTO Concerto values (3, 3, 1, '2022-02-10 00:00:00', '2022-02-10 00:00:30', 1000);


-- INSERT INTO Concerto values (1, 1, 1, '2022-02-10 00:00:00', '2022-02-10 00:00:10', 1000);
-- INSERT INTO Concerto values (2, 2, 1, '2022-05-10 00:00:00', '2022-05-10 00:00:05', 1000);
-- INSERT INTO Concerto values (3, 3, 1, '2022-02-10 00:00:00', '2022-02-10 00:00:30', 1000);
