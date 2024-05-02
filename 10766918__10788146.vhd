library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.numeric_std.ALL;

entity project_reti_logiche is
    port (
        i_clk       : in std_logic;
        i_rst       : in std_logic;
        i_start     : in std_logic;
        i_add       : in std_logic_vector(15 downto 0);
        i_k         : in std_logic_vector(9 downto 0);
        
        o_done      : out std_logic;
        
        o_mem_addr  : out std_logic_vector(15 downto 0);
        i_mem_data  : in std_logic_vector(7 downto 0);
        o_mem_data  : out std_logic_vector(7 downto 0);
        o_mem_we    : out std_logic;
        o_mem_en    : out std_logic
    );
end project_reti_logiche;

architecture project_reti_logiche_arch of project_reti_logiche is
    type state is   (RST,
                     INIT,
                     COPY_K_ADD,
                     DEC_K_START,
                     READ_ENABLE_START,
                     READ_WAIT_START,
                     READ_DATA_START,
                     POS_START,
                     ZERO_START,
                     C_POS_START,
                     C_ZERO_START,
                     DEC_K,
                     READ_ENABLE,
                     READ_WAIT,
                     READ_DATA,
                     POS,
                     ZERO,
                     C,
                     FINE);
    signal curr_state : state;
    
    signal curr_store_value : std_logic_vector(7 downto 0);
    signal next_store_value : std_logic_vector(7 downto 0);
    
    signal curr_c : std_logic_vector(7 downto 0);
    signal next_c : std_logic_vector(7 downto 0);
    
    signal curr_read_value : std_logic_vector(7 downto 0);
    signal next_read_value : std_logic_vector(7 downto 0);
    
    signal curr_addr : std_logic_vector(15 downto 0);
    signal next_addr : std_logic_vector(15 downto 0);
    
    signal curr_k : std_logic_vector(9 downto 0);
    signal next_k : std_logic_vector(9 downto 0);

begin

 process(i_clk, i_rst)
    -- Sequenziale: funzione di stato prossimo
    begin
        if i_rst = '1' then
            curr_state <= RST;
        elsif i_clk'event and i_clk = '1' then
            curr_k <= next_k;
            curr_addr <= next_addr;
            curr_store_value <= next_store_value;
            curr_read_value <= next_read_value;
            curr_c <= next_c;
             
           case curr_state is
              when RST =>
                if(i_rst = '0') then
                    curr_state <= INIT;
                end if;
                
              when INIT =>
                if(i_start = '0') then
                    curr_state <= INIT;
                elsif(i_start = '1') then
                    curr_state <= COPY_K_ADD;
                end if;
                
              when COPY_K_ADD =>
                if(unsigned(next_k)>0) then
                    curr_state <= READ_ENABLE_START;
                elsif (unsigned(next_k)=0) then
                    curr_state <= FINE;
                end if;
                
               when READ_ENABLE_START =>
                curr_state <= READ_WAIT_START;
                
               when READ_WAIT_START =>
                curr_state <= READ_DATA_START;
                
               when READ_DATA_START =>
                if(unsigned(next_read_value)>0) then
                    curr_state <= POS_START;
                elsif(unsigned(next_read_value)=0) then
                    curr_state <= ZERO_START;
                end if;
                
               when POS_START =>
                curr_state <= C_POS_START;
                
               when ZERO_START =>
                curr_state <= C_ZERO_START;
                
               when C_ZERO_START =>
                curr_state <= DEC_K_START;
                
               when C_POS_START =>
                curr_state <= DEC_K;
                
               when DEC_K_START =>
                if(unsigned(next_k)>0) then
                    curr_state <= READ_ENABLE_START;
                elsif(unsigned(next_k)=0) then
                    curr_state <= FINE;
                end if;
                
               when DEC_K =>
                if(unsigned(next_k)>0) then
                    curr_state <= READ_ENABLE;
                elsif(unsigned(next_k)=0) then
                    curr_state <= FINE;
                end if;
                
               when READ_ENABLE =>
                curr_state <= READ_WAIT;
                
                when READ_WAIT =>
                curr_state <= READ_DATA;
               
               when READ_DATA =>
                if(unsigned(next_read_value)>0) then
                    curr_state <= POS;
                elsif(unsigned(next_read_value)=0) then
                    curr_state <= ZERO;
                end if;
                
               when POS =>
                curr_state <= C;
                
               when ZERO =>
                curr_state <= C;
                
               when C =>
                curr_state <= DEC_K;
                
               when FINE =>
                if(i_start = '0') then
                    curr_state <= INIT;
                elsif(i_start = '1') then
                    curr_state <= FINE;
                end if;
                
               when others =>   
           end case;
        end if;
 end process;
 
 process(curr_state)
 --Combinatorio: funzione di uscita
    begin
     next_k <= curr_k;
     next_addr <= curr_addr;
     next_store_value <= curr_store_value;
     next_read_value <= curr_read_value;
     next_c <= curr_c;
     
     o_mem_we <= '0';
     o_mem_en <= '0';
     o_done <= '0';
     o_mem_addr <= (others => '0');
     o_mem_data <= (others => '0');
    
    case curr_state is
        when COPY_K_ADD =>
            next_k <= i_k;
            next_addr <= i_add;   
        when READ_ENABLE_START =>
            o_mem_en <= '1';
            o_mem_addr <= curr_addr;
        when READ_DATA_START =>
            next_read_value <= i_mem_data;
        when POS_START =>
            next_store_value <= curr_read_value;
            next_c <= "00011111";
            next_addr <= std_logic_vector(unsigned(curr_addr)+1);
        when C_POS_START =>
            o_mem_en <= '1';
            o_mem_we <= '1';
            o_mem_addr <= curr_addr;
            o_mem_data <= curr_c;
            next_addr <= std_logic_vector(unsigned(curr_addr)+1);
        when ZERO_START =>
            next_c <= "00000000";
            next_addr <= std_logic_vector(unsigned(curr_addr)+1);
        when C_ZERO_START =>
            o_mem_en <= '1';
            o_mem_we <= '1';
            o_mem_addr <= curr_addr;
            o_mem_data <= curr_c;
            next_addr <= std_logic_vector(unsigned(curr_addr)+1);
        when DEC_K_START =>
            next_k <= std_logic_vector(unsigned(curr_k)-1);
        when DEC_K =>
            next_k <= std_logic_vector(unsigned(curr_k)-1);
        when READ_ENABLE =>
            o_mem_en <= '1';
            o_mem_addr <= curr_addr;
        when READ_DATA =>
            next_read_value <= i_mem_data;
        when POS =>
            next_store_value <= curr_read_value;
            next_c <= "00011111";
            next_addr <= std_logic_vector(unsigned(curr_addr)+1);
        when C =>
            o_mem_en <= '1';
            o_mem_we <= '1';
            o_mem_addr <= curr_addr;
            o_mem_data <= curr_c;
            next_addr <= std_logic_vector(unsigned(curr_addr)+1);
        when ZERO =>
            o_mem_en <= '1';
            o_mem_we <= '1';
            o_mem_addr <= curr_addr;
            o_mem_data <= curr_store_value;
            if unsigned(curr_c) > 0 then
                next_c <= std_logic_vector(unsigned(curr_c)-1);
            end if;
            next_addr <= std_logic_vector(unsigned(curr_addr)+1);
         when FINE =>
            o_done <= '1';
         when others =>
      end case;
    end process;

end project_reti_logiche_arch;
