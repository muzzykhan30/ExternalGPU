# ExternalGPU

Picture this: You have a laptop. It opens pdfs, runs word, excel and youtube just fine. Maybe the occassional stutter or lag here or there, but for basic tasks it is serviceable.

What if you want to jump into something a little more hardware intensive?
Maybe you want to jump into the world of Wukong, dress up as a Cowboy and lose a whole weekend in Red Dead Redemption 2.
OR maybe you want to get into video editing, 3D animations, CAD, or contribute to projects like Folding@home to help in biomedical research to contribute to creating cures to diseases.

All of these tasks require a GPU. In the current economy, buying 2 sticks of RAM and an SSD will burn through your PC budget. Not to mention the impracticality of having a syncing tasks across multiple PCs, no mobility and no battery backup.
Lets use our existing laptop and add a GPU to enable all of these tasks.

What you'll need:
A laptop.
A GPU
A PSU
A device to connect the external hardware to your laptop.

There are multiple ways to do this:
ExpressCard: It is an old technology that was used to connect Extension slots to Laptops.

MiniPCIE: It is the slot that your Wifi Card uses.

M.2 PCIE: The slot that SSDs use.

Oculink: It is a new standard to connect PCIE devices to your system.

Thunderbolt: It used thunderbolt ports that resemble USB C ports to connect external devices and displays to your laptop.

Thunderbolt is the simplest. You buy a ThunderBolt enclosure, you add a GPU, a PSU and connect via the ThunderBolt port. Laptops like the LG Gram are a good example.
However ThunderBolt is mostly reserved fot high end laptops and the compatibility is hit or miss. Also ThunderBolt EGPU enclosures cost a lot and the bandwidth is not as high as other solutions so you will lose some performance.
[Cred: LinusTechTips on YT]

<img width="1459" height="786" alt="image" src="https://github.com/user-attachments/assets/e6400565-2dc3-4f06-9c4c-571274905470" />


ExpressCard is an ancient standard and no recently released laptop is likely to have an ExpressCard slot. It can be used to connect a low powered GPU to your laptop, but in most cases your CPU will be too old to run any modern tasks and will heavily bottleneck the GPU.
<img width="570" height="445" alt="image" src="https://github.com/user-attachments/assets/273b6ea9-607a-4cff-ad10-c7d13b9341f5" />


MiniPCIE is readily available in most laptops. HOWEVER, it is used up by your Wireless Card and removing it would mean you would lose out on wireless connectivity [no Wifi, no Bluetooth]. This could be fixed by using an external Wifi card but at that point you're losing internal and external ports and still having bandwidth limitations.

<img width="891" height="753" alt="image" src="https://github.com/user-attachments/assets/d7fffaf7-2848-4a56-a009-4d0f32526290" />

M.2 PCIE is the slot your nvme SSDs use. Many new laptops have 2 SSD slots and one of the slots is empty. In my case, the Moto Book 60 has 2 m.2 slots and one is empty by default.

<img width="364" height="401" alt="image" src="https://github.com/user-attachments/assets/da245f01-b60a-4700-9498-93ad9b61b5e7" />

<img width="708" height="761" alt="image" src="https://github.com/user-attachments/assets/ba4a5463-b169-4f2f-8874-385b005d3442" />

<img width="411" height="263" alt="image" src="https://github.com/user-attachments/assets/dd3dd40e-3aa4-48c7-8f37-069fac524895" />


So we can use a PCIE adapter or an oculink to PCIE adapter and connect the GPU and PSU to the laptop.



Here are gaming benchmarks comparing ThunderBolt 4, ThunderBolt 5, m.2 PCIe gen 4 and Gen 5 
[Cred: Jarrod's Tech on Youtube]

<img width="919" height="504" alt="image" src="https://github.com/user-attachments/assets/36abd1a8-92b3-4536-b782-4a39bfa316b8" />

Here are some examples of how it will look in your system.

<img width="461" height="520" alt="image" src="https://github.com/user-attachments/assets/e9d0d8a1-ff25-4c2c-a546-956ae0fe1ecf" />

<img width="463" height="592" alt="image" src="https://github.com/user-attachments/assets/f308ad8c-72e6-46d9-85b4-1e0b28203d0b" />

<img width="631" height="492" alt="image" src="https://github.com/user-attachments/assets/2e64da18-9ea1-43e6-b10a-8dacbe5703a4" />


So to conclude, using an EGPU enclosure is a cost effective way of adding a GPU to your laptop for gaming, Productivity and LLM tasks.
