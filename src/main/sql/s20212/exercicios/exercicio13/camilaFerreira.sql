DO $$ BEGIN
    PERFORM drop_functions();
    PERFORM drop_tables();
END $$;

DROP TABLE IF EXISTS campeonato CASCADE;
DROP TABLE IF EXISTS time_ CASCADE;
DROP TABLE IF EXISTS jogo CASCADE;

CREATE TABLE campeonato (
    codigo TEXT NOT NULL,
	nome TEXT NOT NULL,
	ano INTEGER NOT NULL,
    CONSTRAINT campeonato_pk
        PRIMARY KEY (codigo));

CREATE TABLE time_ (
    sigla TEXT NOT NULL,
	nome TEXT NOT NULL,
	CONSTRAINT time_pk
		PRIMARY KEY (sigla));

CREATE TABLE jogo(
	campeonato TEXT NOT NULL, 
	numero INTEGER NOT NULL,
	time1 TEXT NOT NULL,
	time2 TEXT NOT NULL,
	gols1 INTEGER NOT NULL,
	gols2 INTEGER NOT NULL,
	data_ DATE NOT NULL DEFAULT CURRENT_DATE,
	CONSTRAINT jogo_pk
	PRIMARY KEY (campeonato,numero),
	CONSTRAINT jogo_campeonato_fk
	FOREIGN KEY	(campeonato)
	REFERENCES campeonato (codigo),
	CONSTRAINT jogo_time_fk1
	FOREIGN KEY	(time1)
	REFERENCES time_ (sigla),
	CONSTRAINT jogo_time_fk2
	FOREIGN KEY	(time2)
	REFERENCES time_ (sigla));

INSERT INTO campeonato VALUES('1', 'Brasileiro', 2021);
INSERT INTO time_ VALUES('FLA', 'Flamengo'),
                        ('BOT', 'Botafogo'),
                        ('VSC', 'VASCO'),
                        ('FLU', 'Fluminense');

INSERT INTO jogo VALUES('1', 1, 'FLA', 'BOT', 7, 7),
                        ('1', 2, 'FLA', 'VSC', 1, 0),
                        ('1', 3, 'FLA', 'FLU', 5, 0),
                        ('1', 4, 'BOT', 'VSC', 1, 2),
                        ('1', 5, 'BOT', 'FLU', 3, 2),
                        ('1', 6, 'VSC', 'FLU', 0, 1),
                        ('1', 7, 'VSC', 'FLA', 0, 4),
                        ('1', 8, 'FLU', 'FLA', 0, 1),
                        ('1', 9, 'BOT', 'FLA', 0, 0),
                        ('1', 10, 'FLU', 'BOT', 0, 0),
                        ('1', 11, 'FLU', 'VSC', 1, 0),
                        ('1', 12, 'VSC', 'BOT', 1, 0);


CREATE OR REPLACE FUNCTION classificacao(codigo TEXT, pos1 INTEGER, pos2 INTEGER)
RETURNS TABLE(nome TEXT, ponto INTEGER, vitoria INTEGER, empate INTEGER, derrota INTEGER) AS $$

DECLARE
    y RECORD;
    V INTEGER;
    D INTEGER;
    E INTEGER;
    pontos INTEGER;
    
BEGIN
    CREATE TEMPORARY TABLE tabela(nome TEXT, po INTEGER, vi INTEGER, em INTEGER, de INTEGER );
    FOR y IN SELECT * FROM time_ LOOP
        SELECT COUNT (*) FROM jogo WHERE (campeonato = codigo) AND ((time1 = y.sigla AND gols1 > gols2) OR (time2 = y.sigla AND gols2>gols1)) INTO V;
        SELECT COUNT (*) FROM jogo WHERE (campeonato = codigo) AND ((time1 = y.sigla AND gols1 < gols2) OR (time2 = y.sigla AND gols2 < gols1)) INTO D;
        SELECT COUNT (*) FROM jogo WHERE (campeonato = codigo) AND ((time1 = y.sigla AND gols1 = gols2) OR (time2 = y.sigla AND gols2 = gols1)) INTO E;
        pontos := 3*V + E;
        INSERT INTO tabela VALUES (y.sigla,pontos,V,E,D);
        
    END LOOP;
    RETURN QUERY SELECT * FROM tabela ORDER BY(tabela.po, tabela.vi) DESC LIMIT pos2 OFFSET pos1;
    
END;
$$ LANGUAGE plpgsql;

SELECT * FROM classificacao('1', 0, 4);