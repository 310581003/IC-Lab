import random as rd

f_DRAM_read = open("C:/Users/User/Desktop/Lab09/dram.dat", "w")


# DRAM_read instruction
def DRAM_read_intruction() :
    for i in range(0x10000, 0x10800, 4) :
        if (i%8==4 and i!=0x10004 and i<= 0x107dc):
            
            f_DRAM_read.write('@' + format(i, 'x') + '\n')
            temp_hex = rd.randint(0, 0)
            temp = 	format( temp_hex, 'x')
            if (len(temp)<2):
                temp = '0' + temp

            f_DRAM_read.write( temp )
            f_DRAM_read.write('  ')
            temp_hex = rd.randint(0, 0)
            temp = 	format( temp_hex, 'x')
            if (len(temp)<2):
                temp = '0' + temp

            f_DRAM_read.write( temp )
            f_DRAM_read.write('  ')
            temp_hex = rd.randint(0, 0xff)
            temp = 	format( temp_hex, 'x')
            if (len(temp)<2):
                temp = '0' + temp

            f_DRAM_read.write( temp )
            f_DRAM_read.write('  ')
            temp_hex = rd.randint(0, 0xff)
            temp = 	format( temp_hex, 'x')
            if (len(temp)<2):
                temp = '0' + temp

            f_DRAM_read.write( temp )
            f_DRAM_read.write('\n ')

        elif (i%8==4 and i!=0x10004 and i> 0x107dc):
            
            f_DRAM_read.write('@' + format(i, 'x') + '\n')
            temp_hex = rd.randint(0xff,0xff)
            temp = 	format( temp_hex, 'x')
            if (len(temp)<2):
                temp = '0' + temp

            f_DRAM_read.write( temp )
            f_DRAM_read.write('  ')
            temp_hex = rd.randint(0xff, 0xff)
            temp = 	format( temp_hex, 'x')
            if (len(temp)<2):
                temp = '0' + temp

            f_DRAM_read.write( temp )
            f_DRAM_read.write('  ')
            temp_hex = rd.randint(0, 0xff)
            temp = 	format( temp_hex, 'x')
            if (len(temp)<2):
                temp = '0' + temp

            f_DRAM_read.write( temp )
            f_DRAM_read.write('  ')
            temp_hex = rd.randint(0, 0xff)
            temp = 	format( temp_hex, 'x')
            if (len(temp)<2):
                temp = '0' + temp

            f_DRAM_read.write( temp )
            f_DRAM_read.write('\n ')

        else:
            
            f_DRAM_read.write('@' + format(i, 'x') + '\n')
            temp_hex = rd.randint(0, 0xff)
            temp = 	format( temp_hex, 'x')
            if (len(temp)<2):
                temp = '0' + temp

            f_DRAM_read.write( temp )
            f_DRAM_read.write('  ')
            temp_hex = rd.randint(0, 0xff)
            temp = 	format( temp_hex, 'x')
            if (len(temp)<2):
                temp = '0' + temp

            f_DRAM_read.write( temp )
            f_DRAM_read.write('  ')
            temp_hex = rd.randint(0, 0xff)
            temp = 	format( temp_hex, 'x')
            if (len(temp)<2):
                temp = '0' + temp

            f_DRAM_read.write( temp )
            f_DRAM_read.write('  ')
            temp_hex = rd.randint(0, 0xff)
            temp = 	format( temp_hex, 'x')
            if (len(temp)<2):
                temp = '0' + temp

            f_DRAM_read.write( temp )
            f_DRAM_read.write('\n ')




if __name__ == '__main__' :
	DRAM_read_intruction()

f_DRAM_read.close()