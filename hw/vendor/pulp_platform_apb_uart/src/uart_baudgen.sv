//
// UART 16750
//
// Converted to System Verilog by Jonathan Kimmitt
// This version has been partially checked with formality but some bugs remain
// Original Author:   Sebastian Witt
// Date:     14.03.2019
// Version:  1.6
//
// History:  1.0 - Initial version
//           1.1 - THR empty interrupt register connected to RST
//           1.2 - Registered outputs
//           1.3 - Automatic flow control
//           1.4 - De-assert IIR FIFO64 when FIFO is disabled
//           1.5 - Inverted low active outputs when RST is active
//           1.6 - Converted to System Verilog
//
//
// This code is free software; you can redistribute it and/or
// modify it under the terms of the GNU Lesser General Public
// License as published by the Free Software Foundation; either
// version 2.1 of the License, or (at your option) any later version.
//
// This code is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
// Lesser General Public License for more details.
//
// You should have received a copy of the GNU Lesser General Public
// License along with this library; if not, write to the
// Free Software  Foundation, Inc., 59 Temple Place, Suite 330,
// Boston, MA  02111-1307  USA
//

module uart_baudgen(
	input wire		CLK,
	input wire		RST,
	input wire		CE,
	input wire		CLEAR,
	input wire	[15:0] 	DIVIDER,
	output logic		BAUDTICK); // 507
/* design uart_baudgen */
/* architecture rtl */
typedef enum {FALSE,TRUE} bool_t; // 527
reg [15:0] iCounter; // 605

always @(posedge CLK or posedge RST)
begin
if ((RST ==  1'b1))
  begin
  /* block const 263 */
iCounter <= (0<<15)|(0<<14)|(0<<13)|(0<<12)|(0<<11)|(0<<10)|(0<<9)|(0<<8)|(0<<7)|(0<<6)|(0<<5)|(0<<4)|(0<<3)|(0<<2)|(0<<1)|(0<<0);
BAUDTICK <=  1'b0; // 413
      end
  else
  begin
  if ((CLEAR ==  1'b1))
          begin
      /* block const 263 */
iCounter <= (0<<15)|(0<<14)|(0<<13)|(0<<12)|(0<<11)|(0<<10)|(0<<9)|(0<<8)|(0<<7)|(0<<6)|(0<<5)|(0<<4)|(0<<3)|(0<<2)|(0<<1)|(0<<0);
      end
          else if     ((CE ==  1'b1))
          begin
      iCounter <= iCounter + 1; // 413
              end
      BAUDTICK <=  1'b0; // 413
    if ((iCounter == $unsigned(DIVIDER)))
          begin
      /* block const 263 */
iCounter <= (0<<15)|(0<<14)|(0<<13)|(0<<12)|(0<<11)|(0<<10)|(0<<9)|(0<<8)|(0<<7)|(0<<6)|(0<<5)|(0<<4)|(0<<3)|(0<<2)|(0<<1)|(0<<0);
BAUDTICK <=  1'b1; // 413
              end
      
  end
  
end

endmodule // uart_baudgen
