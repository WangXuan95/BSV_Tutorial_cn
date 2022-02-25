# 概述：对数组进行原地快速排序
# Author: WangXuan
# 
# 系统要求：1、具有一个大小至少为0x1000 Byte的数据RAM （该程序中，其高地址用作栈，低地址用作被排序的数组）
#           2、测试该代码时，不需要初始化DataRam，只需要将指令流烧入InstrRam。因为有一系列指令去准备被排序的数组。
#           3、请根据实际情况将a0设置为你的DataRam的地址，例如我的SoC DataRam起始地址为0x00000000，则第一条指令就是 lui a0, 0x00000
#


.org 0x0
    .global _start
_start:

main:                        # main函数开始，在DataRam里初始化一段数据，然后调用QuickSort进行排序，排序后进入死循环。请使用仿真或UART调试器查看排序后的数据
    lui    a0, 0x00000       # 设置DataRam的起始地址为0x00000000，也用作被排序数组的起始地址是，即DataRam的起始地址
    addi   sp, a0  , 0x400   # 设置栈顶指针

    or     a2, a0, zero
    
    addi   t0, zero, -3      # 用一系列指令向a0里写入被排序的数组，可以是负数
    sw     t0,  (a2)
    addi   a2, a2, 4
    addi   t0, zero, -7
    sw     t0,  (a2)
    addi   a2, a2, 4
    addi   t0, zero, 6
    sw     t0,  (a2)
    addi   a2, a2, 4
    addi   t0, zero, 5
    sw     t0,  (a2)
    addi   a2, a2, 4
    addi   t0, zero, -2
    sw     t0,  (a2)
    addi   a2, a2, 4
    addi   t0, zero, 2
    sw     t0,  (a2)
    addi   a2, a2, 4
    addi   t0, zero, -9
    sw     t0,  (a2)
    addi   a2, a2, 4
    addi   t0, zero, -4
    sw     t0,  (a2)
    addi   a2, a2, 4
    addi   t0, zero, -6
    sw     t0,  (a2)
    addi   a2, a2, 4
    addi   t0, zero, 8
    sw     t0,  (a2)
    addi   a2, a2, 4
    addi   t0, zero, 1
    sw     t0,  (a2)
    addi   a2, a2, 4
    addi   t0, zero, -5
    sw     t0,  (a2)
    addi   a2, a2, 4
    addi   t0, zero, 7
    sw     t0,  (a2)
    addi   a2, a2, 4
    addi   t0, zero, 0
    sw     t0,  (a2)
    addi   a2, a2, 4
    addi   t0, zero, 3
    sw     t0,  (a2)
    addi   a2, a2, 4
    addi   t0, zero, -1
    sw     t0,  (a2)
    addi   a2, a2, 4
    addi   t0, zero, 4
    sw     t0,  (a2)
    addi   a2, a2, 4
    addi   t0, zero, 9
    sw     t0,  (a2)
    addi   a2, a2, 4
    addi   t0, zero, -8
    sw     t0,  (a2)
    addi   a2, a2, 4
    addi   t0, zero, -3
    sw     t0,  (a2)
    addi   a2, a2, 4
    addi   t0, zero, -7
    sw     t0,  (a2)
    addi   a2, a2, 4
    addi   t0, zero, 6
    sw     t0,  (a2)
    addi   a2, a2, 4
    addi   t0, zero, 5
    sw     t0,  (a2)
    addi   a2, a2, 4
    addi   t0, zero, -2
    sw     t0,  (a2)
    addi   a2, a2, 4
    addi   t0, zero, 2
    sw     t0,  (a2)
    addi   a2, a2, 4
    addi   t0, zero, -9
    sw     t0,  (a2)
    addi   a2, a2, 4
    addi   t0, zero, -4
    sw     t0,  (a2)
    addi   a2, a2, 4
    addi   t0, zero, -6
    sw     t0,  (a2)
    addi   a2, a2, 4
    addi   t0, zero, 8
    sw     t0,  (a2)
    addi   a2, a2, 4
    addi   t0, zero, 1
    sw     t0,  (a2)
    addi   a2, a2, 4
    addi   t0, zero, -5
    sw     t0,  (a2)
    addi   a2, a2, 4
    addi   t0, zero, 7
    sw     t0,  (a2)
    addi   a2, a2, 4
    addi   t0, zero, 0
    sw     t0,  (a2)
    addi   a2, a2, 4
    addi   t0, zero, 3
    sw     t0,  (a2)
    addi   a2, a2, 4
    addi   t0, zero, -1
    sw     t0,  (a2)
    addi   a2, a2, 4
    addi   t0, zero, 4
    sw     t0,  (a2)
    addi   a2, a2, 4
    addi   t0, zero, 9
    sw     t0,  (a2)
    addi   a2, a2, 4
    addi   t0, zero, -8
    sw     t0,  (a2)

    or     a1, zero, zero      # 准备函数参数，a1=0
    sub    a2, a2, a0          # 准备函数参数，a2=数组最后一个元素的地址偏移
    jal    ra  , QuickSort     # 开始排序
infinity_loop:
    jal   zero, infinity_loop  # 排序结束，死循环

QuickSort:
    # 函数:QuickSort：以a0为基地址的原地升序快速排序，a1是start即开始下标，a2是end即结束下标
    # 例:  a0=0x00000100，a1=0, a2=32，则计算从0x00000100开始的32个4Byte数的快速排序
    # 注:  以有符号数为比较标准。例如0xffffffff应该排在0x00000001前面，因为0xffffffff代表-1，比1要小
    # 之所以使用低13位，因为13位二进制数取值范围位0~8191，不会超过4位十进制数
    # 改变数据RAM： 除了被排序的数组外，还使用了以sp寄存器为栈顶指针的栈。使用栈的大小根据排序长度而不同，调用前合理设置sp的值以防爆栈
    # 改变的寄存器： t0, t1, t2, t3, t4

        bge    a1, a2, QuickSortReturn                # if a1>=a2, end<=start, jump to return
        or     t1, a1, zero                           # t1=i=a1=start
        or     t2, a2, zero                           # t2=j=a2=end
        add    t0, a0, t1                             # 
        lw     t0, (t0)                               # t0=key=lst[start]

        PartationStart:          
            PartationFirstStart:                      # start of for loop
                bge    t1, t2, PartationEnd           # if i>=j, branch to next step
                add    t3, a0, t2                     # 
                lw     t3, (t3)                       # t3=lst[j]
                blt    t3, t0, PartationFirstEnd      # if lst[j]<key, branch to next step
                addi   t2, t2, -4                     # t2-=4  j--
                jal    zero, PartationFirstStart      # for loop
            PartationFirstEnd:                        # end of for loop
            add    t4  , a0, t1                       # t4=lst+i
            sw     t3  , (t4)                         # lst[i] = t3 = lst[j]
            
            PartationSecondStart:                     # start of for loop
                bge    t1, t2, PartationEnd           # if i>=j, branch to next step
                add    t3, a0, t1                     # 
                lw     t3, (t3)                       # t3=lst[i]
                blt    t0, t3, PartationSecondEnd     # if key<lst[i], branch to next step
                addi   t1, t1, 4                      # t1+=4  i++
                jal    zero, PartationSecondStart     # for loop
            PartationSecondEnd:                       # end of for loop 
            add    t4  , a0, t2                       # t4=lst+j
            sw     t3  , (t4)                         # lst[j] = t3 = lst[i]
            
            blt    t1, t2, PartationStart             # if t1<t2, branch to while start
        PartationEnd:

        add    t4  , a0, t1                           # t4=lst+i
        sw     t0  , (t4)                             # lst[i] = t0 = key
        
        addi   sp, sp, -4                              # sp-=4        
        sw     ra, (sp)                                # mem[sp] = ra # push ra to stack
        addi   sp, sp, -4                              # sp-=4
        sw     a1, (sp)                                # mem[sp] = a1 # push a1 to stack, save start
        addi   sp, sp, -4                              # sp-=4        
        sw     a2, (sp)                                # mem[sp] = a2 # push a2 to stack, save end
        addi   sp, sp, -4                              # sp-=4        
        sw     t1, (sp)                                # mem[sp] = t1 # push t1 to stack, save i
        addi   a2, t1, -4                              # a2 = i-4, a parameter for recursive call
        jal    ra  , QuickSort
        lw     t1, (sp)                                # pop i form stack 
        addi   sp, sp,  4                              # sp+=4
        lw     a2, (sp)                                # pop end form stack 
        addi   sp, sp,  4                              # sp+=4
        lw     a1, (sp)                                # pop start form stack 

        addi   sp, sp, -4                              # sp-=4        
        sw     a2, (sp)                                # mem[sp] = a2 # push a2 to stack, save end
        addi   sp, sp, -4                              # sp-=4        
        sw     t1, (sp)                                # mem[sp] = t1 # push t1 to stack, save i
        addi   a1, t1, 4                               # a1 = i+4, a parameter for recursive call
        jal    ra  , QuickSort
        lw     t1, (sp)                                # pop i form stack 
        addi   sp, sp,  4                              # sp+=4
        lw     a2, (sp)                                # pop end form stack 
        addi   sp, sp,  4                              # sp+=4
        lw     a1, (sp)                                # pop start form stack 
        addi   sp, sp,  4                              # sp+=4
        lw     ra, (sp)                                # pop ra form stack 
        addi   sp, sp,  4                              # sp+=4

    QuickSortReturn:                                   # 函数结尾
        jalr   zero, ra, 0                             # 返回

        


#
# QuickSort函数的等效C代码:
#   void QuickSort(int *lst, int start, int end){
#       if(end>start){
#           int i = start,j = end,key = lst[start];
#           while(i < j){
#               for (;i < j && key <= lst[j];j--);
#               lst[i] = lst[j];
#               for (;i < j && key >= lst[i];i++);
#               lst[j] = lst[i];
#           }
#           lst[i] = key;
#           QuickSort(lst, start, i - 1);
#           QuickSort(lst, i + 1, end);
#       }
#   }
#
#
        