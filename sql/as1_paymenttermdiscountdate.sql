-- Function: as1_paymenttermdiscountdate(numeric, timestamp with time zone, timestamp with time zone, character varying, character varying)

-- DROP FUNCTION as1_paymenttermdiscountdate(numeric, timestamp with time zone, timestamp with time zone, character varying, character varying);

CREATE OR REPLACE FUNCTION as1_paymenttermdiscountdate(paymentterm_id numeric, docdate timestamp with time zone, paydate timestamp with time zone, discount2 character varying, subgracedays character varying)
  RETURNS timestamp with time zone AS
$BODY$
/***************************************************************************
 *  Title:	SQL-function to calculate the discountdate                     *
 *  Description:                                                           *
 *	Calculates the discountdate for the terms of payment                   *
 ***************************************************************************
 * This function is free software; you can redistribute it and/or modify   *
 * it under the terms of the GNU General Public License as published by    *
 * the Free Software Foundation; either version 2 of the License, or       *
 * (at your option) any later version.                                     *
 *                                                                         *
 * This plug-in is distributed in the hope that it will be useful,         *
 * but WITHOUT ANY WARRANTY; without even the implied warranty of          *
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the           *
 * GNU General Public License for more details.                            *
 *                                                                         *
 * You should have received a copy of the GNU General Public License along *
 * with this plug-in; If not, see <http://www.gnu.org/licenses/>.          *
 *                                                                         *
 * function as1_paymenttermdiscountdate based on paymenttermdiscount       *
 * (2014) - Patric Massing (Hans Auler GmbH)                               *
 *                                                                         *
 **************************************************************************/

DECLARE
	Discount1Date		timestamp with time zone;
	Discount2Date		timestamp with time zone;
	Add1Date		NUMERIC := 0;
	Add2Date		NUMERIC := 0;
	p   			RECORD;

BEGIN
	--	No Data - No Discount
	IF (PaymentTerm_ID IS NULL OR DocDate IS NULL) THEN
		RETURN 0;
	END IF;

	FOR p IN 
		SELECT	*
		FROM	C_PaymentTerm
		WHERE	C_PaymentTerm_ID = PaymentTerm_ID
	LOOP	--	for convineance only
		Discount1Date := TRUNC(DocDate + p.DiscountDays + p.GraceDays);
		Discount2Date := TRUNC(DocDate + p.DiscountDays2 + p.GraceDays);

		--	Next Business Day
		IF (p.IsNextBusinessDay='Y') THEN
			Discount1Date := nextBusinessDay(Discount1Date, p.AD_Client_ID);
			Discount2Date := nextBusinessDay(Discount2Date, p.AD_Client_ID);
		END IF;
                -- --> as1 (PM)
		IF (p.fixmonthoffset > 0) THEN
		    Discount1Date := adddays( (date_trunc('month', DocDate) + p.fixmonthoffset * interval '1 month'), (p.discountdays + p.GraceDays -1));
		    Discount2Date := adddays( (date_trunc('month', DocDate) + p.fixmonthoffset * interval '1 month'), (p.discountdays2 + p.GraceDays -1));
		END IF;  
		-- <-- as1 (PM) 
		


	END LOOP;

        IF subgracedays ='Y' THEN

            IF discount2 ='Y' THEN
                RETURN Discount2Date-p.gracedays;
            ELSE    
                RETURN Discount1Date-p.gracedays;
            END IF;

        ELSE

            IF discount2 ='Y' THEN
                RETURN Discount2Date;
            ELSE    
                RETURN Discount1Date;
            END IF;

        END IF;
	
	
	
END;

$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
ALTER FUNCTION as1_paymenttermdiscountdate(numeric, timestamp with time zone, timestamp with time zone, character varying, character varying)
  OWNER TO adempiere;
