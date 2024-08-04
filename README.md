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
<p align="center"><img width="1000" src="https://github.com/user-attachments/assets/fdf347ea-625d-4cc3-8483-bcf709f60d6a")></p>


## FSMD 
<p align="center"><img width="400" img length="700" src="https://github.com/user-attachments/assets/80224cbd-163b-4f63-be44-4b507051037a")></p>

A transaction begins with START_CMD. It initiates the FSM to move through the start1 and start2 states to generate a start condition. A WR_CMD or RD_CMD command should follow. Both read and write actionsgo through the same data states. The data1, data2, data3, and data4 states process a data bit or an acknowledge bit. They are circulated through nine times and bit_reg is used as a counter to keep track of the number of iterations. A separate output control logic controls the direction of data flow based on the type of command. After nine bits are processed, the FSM moves to the data_end state, which lowers the scl and sda lines for a quarter of scl clock. It then moves to the hold state. After completing a command, the FSM stays in the hold state waiting for the next command. The state represents an intermediate “holding point” in a transaction and both scl and sda lines are low in this state. Note that the FSM generates a ready status signal to indicate whether the controller is ready to accept a new command. It is asserted in the idle and hold states.The transaction is ended with a STOP_CMD or RESTART_CMD command. The former makes the FSM move through the stop1 and stop2 states to generate a stop condition and the latter forces the FSM to regenerate a start condition and begin a new transaction.

## I2C IO 
this is just a signal wrapper so that the I2C controller can be integrated into Pongchu's Fpro SoC you can just use the i2c_controller.v directly without the signal wrapper 

### A small note 
Finally, the design uses FPGA I/O pin’s tristate buffer to accommodate the open-drain structure of the I C bus. The HDL code for the scl port, in which the signal flows out of the device, is assign scl = (scl_out_reg) ? 1’bz : 1’b0; In this scheme, the FPGA device turns off the tristate buffer (i.e., changes the output to a high-impedance state) when a desired bus line level is 1. Since the bus line is connected to VDD via a pull-up resistor, it is driven to 1 implicitly when all devices output 1 (i.e., all are in high-impedance state). Note that the scl port uses the tri data type because of the tristate buffer. The HDL code for the sda port is assign sda = (input_en || sda_out) ? 1’bz : 1’b0; The first condition, input_en=’1’, is to turn off the tristate buffer for the slave device to transmit data and the second condition, sda_out=’1’, is to generate an output of 1 via the implicit pull-up resistor circuit. As with the scl port, the tri data type is used because of the tristate buffer.

