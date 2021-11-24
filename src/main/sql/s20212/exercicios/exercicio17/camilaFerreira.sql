DO $$ BEGIN
    PERFORM drop_functions();
    PERFORM drop_tables();
END $$;

CREATE TABLE produto(
    codigo VARCHAR,
    descricao VARCHAR,
    preco FLOAT
);

INSERT INTO produto VALUES  (1,'MacBookPro 2021', 20000),
                            (2,'MacBookAir 2021', 17000),
                            (3,'Avell A62', 8000),
                            (4,'DELL G3', 6500),
                            (5,'Positivo Motion', 50);




CREATE OR REPLACE FUNCTION calcular_preco(cod_prods varchar[], qtds INTEGER[])
RETURNS REAL AS $$
    
    DECLARE
        y RECORD;
        valor REAL := 0;
  
 
    BEGIN
        
        FOR y IN (SELECT t.* FROM unnest(cod_prods, qtds) AS t(cod_produto,quantidade)) LOOP 
        
            valor := valor + ((SELECT preco from produto where (produto.codigo = y.cod_produto))  * y.quantidade);
    
        
        END LOOP;
      
       
       RETURN valor;
    END;

$$ LANGUAGE plpgsql;

SELECT calcular_preco('{"1", "2", "3"}', '{1, 2, 3}');