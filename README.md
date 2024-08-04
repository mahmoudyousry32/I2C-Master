# I2C-Master
There are five basic actions performed by an I2C master controller:
- Write eight bits and check the acknowledge bit.
- Read eight bits and assert an acknowledge or negative- acknowledge bit.
- Generate a start condition.
- Generate a stop condition.
- Generate a restart condition.
Based on the needed transitions, each action can be divided into several phases. The phases of the start, restart, and stop conditions are shown in the figure below Note that both scl and sda lines are high when the bus is idle and both are low after start and restart conditions and after completing transmitting or receiving a byte. We assume that the I2C clock rate is fi2c and its period is tI2C. Each phase is half of tI2C. The start and stop conditions take one I2C clock cycle. The restart condition is similar to the start condition. The controller simply first raises the scl and sda lines to high and then generates a normal start condition. It takes 1.5 I2C clock cycles.
![image](https://github.com/user-attachments/assets/f6d6221e-bddb-4ee0-abb4-71e367a33e5e)


The phases of processing a bit in read or write actions are shown below Each bit takes one I2C clock cycle and the period is divided into four phases, labeled as data1, data2, data3, and data4. An scl clock pulse is generated in this period. The I2C protocol specifies that the data on sda must be stable when scl is high. Correct data exchange can be achieved by placing the data bit on sda at the beginning of the data1 phase in a write operation and retrieving the data bit in the transition between the data2 and data3 phases in a read operation. After nine bits are processed, the scl and sda lines are lowered in preparation for the next action, which is labeled as data_end The I2C controller is constructed by an FSMD and a special output control logic to handle the data bit flow and acknowledgment.
![image](https://github.com/user-attachments/assets/fdf347ea-625d-4cc3-8483-bcf709f60d6a)


## FSMD 
![image](https://github.com/user-attachments/assets/80224cbd-163b-4f63-be44-4b507051037a)




