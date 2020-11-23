CREATE DATABASE parquimetros;
USE parquimetros;

CREATE TABLE conductores(
    dni INT unsigned NOT NULL,
    nombre VARCHAR(45) NOT NULL,
    apellido VARCHAR(45) NOT NULL,
    direccion VARCHAR(45) NOT NULL,
    telefono VARCHAR(45) ,
    registro INT unsigned NOT NULL,

    CONSTRAINT pk_conductores
    PRIMARY KEY (dni),

    KEY(registro)
) ENGINE=InnoDB;

CREATE TABLE automoviles(
    patente VARCHAR(6) NOT NULL,
    marca  VARCHAR(45) NOT NULL,
    modelo VARCHAR(45) NOT NULL,
    color VARCHAR(45) NOT NULL,
	 dni INT UNSIGNED NOT NULL,
	CONSTRAINT pk_automoviles
	PRIMARY KEY (patente),
	
    CONSTRAINT FK_automoviles_conductores
    FOREIGN KEY (dni) REFERENCES conductores(dni)
	ON DELETE RESTRICT ON UPDATE CASCADE

)ENGINE=InnoDB;
CREATE TABLE tipos_tarjeta(
	tipo VARCHAR(45) NOT NULL,
	descuento DECIMAL(3,2) unsigned 
		CHECK (descuento >=0.00 OR descuento <= 1.00) NOT NULL,
	
	CONSTRAINT pk_tipo
	PRIMARY KEY (tipo)
)ENGINE=InnoDB;
CREATE TABLE tarjetas(
	id_tarjeta SMALLINT unsigned NOT NULL AUTO_INCREMENT,
	saldo DECIMAL(5,2) UNIQUE NOT NULL,
	tipo VARCHAR(45) NOT NULL,
	patente VARCHAR(6) NOT NULL,
	CONSTRAINT pk_tarjetas
	PRIMARY KEY(id_tarjeta),
	
	CONSTRAINT fk_tarjetas_tipos_tarjetas
	FOREIGN KEY (tipo) REFERENCES tipos_tarjeta(tipo),
	
	CONSTRAINT fk_tarjetas_automoviles
	FOREIGN KEY (patente) REFERENCES automoviles(patente)
)ENGINE=InnoDB;
CREATE TABLE inspectores (
	legajo INT unsigned NOT NULL, 
	dni INT unsigned NOT NULL,
	nombre VARCHAR(45) NOT NULL,
	apellido VARCHAR(45) NOT NULL,
	password CHAR(32) NOT NULL,
	
	CONSTRAINT pk_inspectores
	PRIMARY KEY (legajo)

)ENGINE=InnoDB;
CREATE TABLE ubicaciones(
	calle VARCHAR(45) NOT NULL,
	altura SMALLINT unsigned NOT NULL,
	tarifa DECIMAL(5,2) unsigned NOT NULL,
	
	CONSTRAINT pk_ubicaciones
	PRIMARY KEY(calle,altura)
)ENGINE=InnoDB;
CREATE TABLE parquimetros(
	id_parq SMALLINT unsigned NOT NULL,
	numero SMALLINT unsigned NOT NULL,
	calle VARCHAR(45) NOT NULL,
	altura SMALLINT unsigned NOT NULL,
	
	CONSTRAINT pk_parquimetros
	PRIMARY KEY (id_parq),
	
	CONSTRAINT fk_parquimetros_ubicaciones
	FOREIGN KEY (calle,altura) REFERENCES ubicaciones(calle,altura)
		ON DELETE RESTRICT ON UPDATE CASCADE
		
)ENGINE=InnoDB;
CREATE TABLE estacionamientos(
	id_tarjeta SMALLINT unsigned NOT NULL,
	id_parq SMALLINT unsigned NOT NULL,
	fecha_ent DATE NOT NULL,
	hora_ent TIME (0) NOT NULL,
	fecha_sal DATE ,
	hora_sal TIME (0) ,
	CONSTRAINT pk_estacionamientos
	PRIMARY KEY(fecha_ent,hora_ent,id_parq),
	
	CONSTRAINT fk_estacionamientos_parquimetros
	FOREIGN KEY (id_parq) REFERENCES parquimetros(id_parq)
		ON DELETE RESTRICT ON UPDATE CASCADE,
	CONSTRAINT fk_estacionamientos_tarjetas
	FOREIGN KEY (id_tarjeta) REFERENCES tarjetas(id_tarjeta)
		ON DELETE RESTRICT ON UPDATE CASCADE
)ENGINE=InnoDB;
CREATE TABLE accede (
	legajo INT unsigned NOT NULL,
	id_parq SMALLINT unsigned NOT NULL,
	fecha DATE NOT NULL, 
	hora TIME (0) NOT NULL,	
	CONSTRAINT pk_accede
	PRIMARY KEY (id_parq,fecha,hora),
	
	CONSTRAINT fk_accede_parquimetros
	FOREIGN KEY (id_parq) REFERENCES parquimetros (id_parq)
		ON DELETE RESTRICT ON UPDATE CASCADE,
		
	CONSTRAINT fk_accede_inspectores
	FOREIGN KEY (legajo) REFERENCES inspectores (legajo)
		ON DELETE RESTRICT ON UPDATE CASCADE
)ENGINE=InnoDB;
CREATE TABLE asociado_con(
	id_asociado_con SMALLINT unsigned AUTO_INCREMENT,
	legajo INT unsigned NOT NULL,
	calle  VARCHAR(45) NOT NULL,
	altura SMALLINT unsigned NOT NULL,
	dia ENUM("do","lu","ma","mi","ju","vi","sa") NOT NULL,
	turno ENUM("m","t") NOT NULL,
	
	CONSTRAINT pk_asociado
	PRIMARY KEY (id_asociado_con),
	
	CONSTRAINT fk_asociado_inspectores
	FOREIGN KEY (legajo) REFERENCES inspectores(legajo)
		ON DELETE RESTRICT ON UPDATE CASCADE,
		
	CONSTRAINT fk_asociado_ubicaciones
	FOREIGN KEY (calle,altura) REFERENCES ubicaciones(calle,altura)
		ON DELETE RESTRICT ON UPDATE CASCADE

)ENGINE=InnoDB;
CREATE TABLE multa(
	numero SMALLINT unsigned AUTO_INCREMENT,
	fecha DATE NOT NULL,
	hora TIME (0) NOT NULL,
	patente VARCHAR(6) NOT NULL,
	id_asociado_con SMALLINT unsigned NOT NULL,
	
	CONSTRAINT pk_multa
	PRIMARY KEY (numero),
	
	CONSTRAINT fk_multa_automoviles
	FOREIGN KEY (patente) REFERENCES automoviles (patente)
		ON DELETE RESTRICT ON UPDATE CASCADE,
		
	CONSTRAINT fk_multa_asociado 
	FOREIGN KEY (id_asociado_con) REFERENCES asociado_con(id_asociado_con)
		ON DELETE RESTRICT ON UPDATE CASCADE
		
)ENGINE=InnoDB;

CREATE TABLE ventas(
	id_tarjeta SMALLINT unsigned NOT NULL,
	tipo_tarjeta VARCHAR(45) NOT NULL,
	saldo DECIMAL(5,2) NOT NULL,
	fecha DATE NOT NULL,
	hora TIME (0) NOT NULL,
	
	CONSTRAINT pk_ventas
	PRIMARY KEY (id_tarjeta,fecha,hora),
	
	CONSTRAINT fk_ventas_tarjetas
	FOREIGN KEY (id_tarjeta) REFERENCES tarjetas (id_tarjeta)
		ON DELETE RESTRICT ON UPDATE CASCADE,
		
	CONSTRAINT fk_ventas_tipos
	FOREIGN KEY (tipo_tarjeta) REFERENCES tarjetas (tipo)
		ON DELETE RESTRICT ON UPDATE CASCADE,
		
	CONSTRAINT fk_ventas_saldo
	FOREIGN KEY (saldo) REFERENCES tarjetas (saldo)
		ON DELETE RESTRICT ON UPDATE CASCADE
		
)ENGINE=InnoDB;

#-------------------------------------------------------------------------------------------------------------------------------------
delimiter !
CREATE PROCEDURE conectar(IN id_tarjeta INTEGER , IN id_parq INTEGER)
begin
	DECLARE op_t VARCHAR(8);
	DECLARE op_r VARCHAR(4);
	DECLARE est_time INTEGER;
	DECLARE operacion BOOLEAN;
	DECLARE sal INTEGER;
	DECLARE descuento INTEGER;
	DECLARE tarifa INTEGER;
	DECLARE hora_ini TIME;
	DECLARE hora_fin TIME;
	DECLARE fecha_ini DATE;
	DECLARE fecha_fin DATE;
	
	START TRANSACTION;
	SELECT true INTO operacion FROM tarjetas AS t NATURAL JOIN estacionamientos AS e
							   WHERE t.id_tarjeta = id_tarjeta AND e.fecha_sal IS NOT NULL;
	SELECT t.saldo INTO sal FROM tarjetas AS t WHERE t.id_tarjeta = id_tarjeta;
	SELECT tt.descuento INTO descuento FROM tarjetas NATURAL JOIN tipos_tarjeta AS tt WHERE t.id_tarjeta = id_tarjeta;
	SELECT u.tarifa INTO tarifa FROM parquimetro AS p NATURAL JOIN ubicaciones AS u
									WHERE p.calle = u.calle AND p.altura = u.altura;
	SELECT t.saldo INTO sal FROM tarjetas AS t WHERE t.id_tarjeta = id_tarjeta;
	SELECT tt.descuento INTO descuento FROM tarjetas NATURAL JOIN tipos_tarjeta AS tt WHERE t.id_tarjeta = id_tarjeta;
			
	IF operacion THEN
		
		SET op_t="apertura";

		SELECT true INTO operacion FROM tarjetas AS t WHERE t.id_tarjeta = id_tarjeta AND t.saldo > 0;
		IF operacion THEN
			SET op_r = "Ok";
			SET est_time = (sal/(tarifa*(1-descuento))); 
			INSERT INTO estacionamientos(id_tarjeta,id_parq,fecha_ent,hora_ent) VALUES(id_tarjeta,id_parq,curdate(),curtime());
		ELSE
			SET op_r = "Fail";
		END IF;
	ELSE
		SET op_t="cierre";
		
		SET fecha_fin = curdate();
		SET hora_fin = curtime();
		SELECT t.fecha_ent INTO fecha_ini FROM tarjetas AS t WHERE id_tarjeta=t.id_tarjeta;
		SELECT t.hora_ent INTO hora_ini FROM tarjetas AS t WHERE id_tarjeta=t.id_tarjeta; #update no insert
		INSERT INTO estacionamientos VALUES(id_tarjeta,id_parq,fecha_ini,hora_ini,fecha_fin,hora_fin);
		SET est_time = ((fecha_fin+0)-(fecha_ini+0)*1440) + (((hora_fin+0)-(hora_ini+0)+24)%24);
		SET sal = sal-((tarifa*(1-descuento))*ROUND(est_time/60));
		#UPDATE saldo de la tarjetas
	END IF;

	SELECT op_t AS "Tipo de Operacion", op_r AS "Resultado de la operacion", est_time AS "Tiempo Restante Maximo";
	COMMIT;
end; !
delimiter ;
#-------------------------------------------------------------------------------------------------------------------------------------
CREATE VIEW estacionados AS
SELECT p.calle,p.altura,t.patente 
FROM estacionamientos AS e NATURAL JOIN tarjetas AS t NATURAL JOIN parquimetros AS p
WHERE e.fecha_sal IS NULL AND e.hora_sal IS NULL ;

CREATE VIEW info_inspectores AS
SELECT legajo,password FROM inspectores;
#-------------------------------------------------------------------------------------------------------------------------------------
# Creacion de usuarios

CREATE USER 'admin'@'localhost' IDENTIFIED BY 'admin';

GRANT ALL PRIVILEGES ON parquimetros.* TO 'admin'@'localhost' WITH GRANT OPTION;


CREATE USER 'venta'@'%' IDENTIFIED BY 'venta';

GRANT INSERT ON parquimetros.tarjetas TO 'venta'@'%';

CREATE USER 'parquimetro' IDENTIFIED BY 'parq';

GRANT EXECUTE ON PROCEDURE parquimetros.conectar TO 'parquimetro'@'%';

GRANT UPDATE ON parquimetro.estacionamientos TO 'parquimetro'@'%';

GRANT UPDATE ON parquimetro.tarjetas TO 'parquimetro'@'%';

CREATE USER 'inspector'@'%' IDENTIFIED BY 'inspector';

GRANT SELECT ON parquimetros.parquimetros TO 'inspector'@'%';

GRANT SELECT ON parquimetros.estacionados TO 'inspector'@'%';

GRANT SELECT ON parquimetros.multa TO 'inspector'@'%';

GRANT INSERT ON parquimetros.multa TO 'inspector'@'%';

GRANT INSERT ON parquimetros.accede TO 'inspector'@'%';

GRANT SELECT ON parquimetros.ubicaciones TO 'inspector'@'%';

GRANT SELECT ON parquimetros.asociado_con TO 'inspector'@'%';

GRANT SELECT ON parquimetros.tarjetas TO 'inspector'@'%';
