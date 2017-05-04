//
//  ViewController.m
//  GCDDemo
//
//  Created by zhou on 2017/5/2.
//  Copyright © 2017年 zhou. All rights reserved.
//  http://www.cnblogs.com/ludashi/p/5336169.html

#import "ViewController.h"

@interface ViewController ()


@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
}
//同步执行串行队列
- (IBAction)tapButton1:(UIButton *)sender {
    NSLog(@"同步执行串行队列");
    [self performQueueUseSynchronization:[self getSerialQueueWithLabel:@"sync.serial.queue"]];
}
//同步执行并行队列
- (IBAction)tapButton2:(UIButton *)sender {
    NSLog(@"同步执行并行队列");
    [self performQueueUseSynchronization:[self getConcurrentQueueWithLabel:@"sync.concurrent.queue"]];
}
//异步执行串行队列
- (IBAction)tapButton3:(UIButton *)sender {
    NSLog(@"异步执行串行队列");
    [self performQueueUseAsynchronization:[self getSerialQueueWithLabel:@"asyn.serial.queue"]];
}
//异步执行并行队列
- (IBAction)tapButton4:(UIButton *)sender {
    NSLog(@"异步执行并行队列");
    [self performQueueUseAsynchronization:[self getConcurrentQueueWithLabel:@"async.concurrent.queue"]];
}
- (IBAction)tapButton5:(id)sender {
    [self deferPerform:1.0];
}
- (IBAction)tapButton6:(id)sender {
    [self globalQueuePriority];
}
- (IBAction)tapButton7:(id)sender {
    [self setCustomeQueuePriority];
}
- (IBAction)tapButton:(id)sender {
    [self performGroupQueue];
}
- (IBAction)tapButton9:(id)sender {
    [self performGroupUseEnterAndLeave];
}
- (IBAction)tapButton10:(id)sender {
    [self useSemaphoreLock];
}
- (IBAction)tapButton11:(id)sender {
    [self useDispatchApply];
}
- (IBAction)tapButton12:(id)sender {
    [self queueSuspendAndResume];
}
- (IBAction)tapButton13:(id)sender {
    [self useBarrierAsync];
}
- (IBAction)tapButton14:(id)sender {
}
- (IBAction)tapButton15:(id)sender {
}


//使用dispatch_sync在当前线程中执行队列
- (void)performQueueUseSynchronization:(dispatch_queue_t)queue{
    for (int i = 0; i < 3; i ++) {
        dispatch_sync(queue, ^{
          //  [self currentThreadSleep:1];
            [self currentThreadSleep:arc4random()%3];

            NSLog(@"%d",i);
        });
        NSLog(@"%d执行完毕",i);
    }
    NSLog(@"所有队列使用同步方式执行完毕");
}
//使用dispatch_async在当前线程中执行队列
- (void)performQueueUseAsynchronization:(dispatch_queue_t)queue{
    dispatch_queue_t serialQueue = [self getSerialQueueWithLabel:@"serialQueue"];
    for (int i = 0 ; i < 3 ; i ++) {
        dispatch_async(queue, ^{
            [self currentThreadSleep:arc4random()%3+1];
            
            NSThread *currentThread = [self getCurrentThread];
            dispatch_sync(serialQueue, ^{
                NSLog(@"Sleep的线程%@", currentThread);
                NSLog(@"当前输出内容的线程%@",[self getCurrentThread]);
                NSLog(@"执行%d %@",i, queue);
            });
        });
        
        NSLog(@"%d 添加完毕",i);
    }
    NSLog(@"使用异步方式添加队列");
    
}
- (void)deferPerform:(double)time{
    //dispatch_time用于计算相对时间，当设备睡眠时，dispatch_time也就跟着睡眠了
    //参数1 时间参照，从此刻开始计时
//    dispatch_time_t delayTime = dispatch_time(DISPATCH_TIME_NOW, (NSInteger)(time * (double)NSEC_PER_SEC));
//    dispatch_after(delayTime, [self getGlobalQueue], ^{
//        NSLog(@"执行线程 %@ dispatch_time：延迟%f秒执行",[self getCurrentThread], time);
//    });
    
    //dispatch_walltime用于计算绝对时间，dispatch_walltime是根据挂钟来计算的时间，即时设备睡眠了，他也不会睡眠
    __block int timeout = 30;
    dispatch_queue_t queue = [self getGlobalQueue];
    
    dispatch_source_t timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, queue);
    
    dispatch_source_set_timer(timer, dispatch_walltime(NULL, 0), 1.0*NSEC_PER_SEC, 0);//每秒执行
    dispatch_source_set_event_handler(timer, ^{
        if (timeout <= 0) {
            NSLog(@"结束计时");
            dispatch_source_cancel(timer);
            dispatch_async(dispatch_get_main_queue(), ^{
                //设置界面显示， 根据需求设置
            });
        }else{
            NSLog(@"%d",timeout);
            dispatch_async(dispatch_get_main_queue(), ^{
                //设置界面显示， 根据需求设置
            });
        }
        timeout --;
    });
    dispatch_resume(timer);
}

- (void)globalQueuePriority{
    //高 > 默认 > 低 > 后台
    dispatch_queue_t queueHeight = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0);
    dispatch_queue_t queueDefault = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    dispatch_queue_t queueLow = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0);
    dispatch_queue_t queueBackground = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0);
    
    //优先级不是绝对的，大体上会按这个优先级来执行，一般都是使用默认(default)优先级
    dispatch_async(queueLow, ^{
        NSLog(@"Low %@",[self getCurrentThread]);
    });
    dispatch_async(queueBackground, ^{
        NSLog(@"Background %@",[self getCurrentThread]);
    });
    dispatch_async(queueDefault, ^{
        NSLog(@"Default %@",[self getCurrentThread]);
    });
    dispatch_async(queueHeight, ^{
        NSLog(@"High %@",[self getCurrentThread]);
    });
}

- (void)setCustomeQueuePriority{

//    dispatch_queue_t serialQueue = dispatch_queue_create("com.serial", NULL);
//    dispatch_queue_t globalQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0);
//    
//    dispatch_set_target_queue(serialQueue, globalQueue);
    //第一个参数为要设置优先级的queue，第二个参数是参照物，既将第一个queue的优先级和第二个queue的优先级设置成一样
    
    
    //创建三个队列，但是这三个队列还是串行执行，一个执行完才去执行另一个
    //创建目标队列
    dispatch_queue_t targetQueue = dispatch_queue_create("target_queue", DISPATCH_QUEUE_SERIAL);
    
    //创建3个串行队列
    dispatch_queue_t queue1 = dispatch_queue_create("test.1", DISPATCH_QUEUE_SERIAL);
    dispatch_queue_t queue2 = dispatch_queue_create("test.2", DISPATCH_QUEUE_SERIAL);
    dispatch_queue_t queue3 = dispatch_queue_create("test.3", DISPATCH_QUEUE_SERIAL);
    
    //将三个串行队列分别添加到目标队列
    dispatch_set_target_queue(queue1, targetQueue);
    dispatch_set_target_queue(queue2, targetQueue);
    dispatch_set_target_queue(queue3, targetQueue);
    
    dispatch_async(queue1, ^{
        NSLog(@"1 in");
        [NSThread sleepForTimeInterval:3.f];
        NSLog(@"1 out");
    });
    
    dispatch_async(queue2, ^{
        NSLog(@"2 in");
        [NSThread sleepForTimeInterval:3.f];
        NSLog(@"2 out");
    });
    
    dispatch_async(queue3, ^{
        NSLog(@"3 in");
        [NSThread sleepForTimeInterval:3.f];
        NSLog(@"3 out");
    });
   
}

- (void)performGroupQueue{
    NSLog(@"任务组自动管理");
    dispatch_queue_t concurrentQueue = [self getConcurrentQueueWithLabel:@"concurrent.queue"];
    dispatch_group_t group = dispatch_group_create();
    
    //将group与queue进行管理管理，并且自动执行
   
    dispatch_group_async(group, concurrentQueue, ^{
        NSLog(@"任务1开始");
        [self currentThreadSleep:3];
        NSLog(@"任务1结束");
    });
    
    dispatch_group_async(group, concurrentQueue, ^{
        NSLog(@"任务2开始");
        dispatch_queue_t queue = [self getGlobalQueue];
        dispatch_sync(queue, ^{
            NSLog(@"内部执行开始");
            [self currentThreadSleep:1];
            NSLog(@"内部执行结束");
        });
        [self currentThreadSleep:2];
        NSLog(@"任务2结束");
    });
    
    //队列组都执行完毕后会进行通知
    dispatch_group_notify(group, [self getMainQueue], ^{
        NSLog(@"所有任务都执行完毕");
    });
    
    //dispatch_group_wait会阻塞线程，所以不要在主线程里调用它
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        dispatch_group_wait(group, dispatch_time(DISPATCH_TIME_NOW, 5 * NSEC_PER_SEC));
        NSLog(@"阻塞结束");
    });
    
    NSLog(@"异步执行测试，不会阻塞当前线程");
}

- (void)performGroupUseEnterAndLeave{
    NSLog(@"任务组手动管理");
    dispatch_queue_t concurrentQueue = [self getConcurrentQueueWithLabel:@"group.queue"];
    
    dispatch_group_t group = dispatch_group_create();
    
    //将group与queue进行手动关联和管理，并且自动执行
    for (int i = 0 ; i < 3; i ++) {
        dispatch_group_enter(group); //进入队列组
        dispatch_async(concurrentQueue, ^{
            [self currentThreadSleep:1];
            NSLog(@"任务%d 执行完毕",i);
            dispatch_group_leave(group); //出队列组
        });
    }
//    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        dispatch_group_wait(group, DISPATCH_TIME_FOREVER);//阻塞当前线程，直到所有任务执行完毕
        NSLog(@"任务组执行完毕");
//    });
  
    
    dispatch_group_notify(group, concurrentQueue, ^{
        NSLog(@"手动管理的队列执行OK");
    });
}
//信号量同步锁
- (void)useSemaphoreLock{
    dispatch_queue_t concurrenQueue = [self getConcurrentQueueWithLabel:@"sema.queue"];
    
    //创建信号量
    dispatch_semaphore_t semaphorelock = dispatch_semaphore_create(1);
    __block NSInteger testNumber = 0;
    
    for (int i = 0; i < 3; i ++) {
        dispatch_async(concurrenQueue, ^{
            NSLog(@"上锁前");
            dispatch_semaphore_wait(semaphorelock, DISPATCH_TIME_FOREVER);// 上锁
            NSLog(@"上锁后");
            testNumber += 1;
            [self currentThreadSleep:2];
            NSLog(@"%@",[self getCurrentThread]);
            NSLog(@"第%d次执行:testNumber = %ld \n ",i, (long)testNumber);
            dispatch_semaphore_signal(semaphorelock);  //开锁
            NSLog(@"开锁完成");
        });
        NSLog(@"一次添加完成");
    }
    NSLog(@"异步执行测试");
    
    
}

//循环执行
- (void)useDispatchApply{
    NSLog(@"循环多次执行串行队列");
    dispatch_queue_t concurrentQueue = [self getConcurrentQueueWithLabel:@"concurrent.queue"];
    //会阻塞当前线程，但concurrentQueue队列会在新的线程中执行
    dispatch_apply(4, concurrentQueue, ^(size_t index) {
        [self currentThreadSleep:index];
        NSLog(@"第%zu次执行，%@", index, [self getCurrentThread]);
    });
    
    NSLog(@"循环多次执行串行队列");
    dispatch_queue_t serialQueue = [self getSerialQueueWithLabel:@"serial.queue"];
    //会阻塞当前线程 serailQueue队列在当前线程中执行
    dispatch_apply(4, serialQueue, ^(size_t index) {
        [self currentThreadSleep:index];
        NSLog(@"第%zu次执行，%@", index, [self getCurrentThread]);
    });
    
}
- (void)queueSuspendAndResume{
    NSLog(@"暂停和唤醒队列");
    dispatch_queue_t concurrentQueue = [self getConcurrentQueueWithLabel:@"concurrent.queue"];
    dispatch_suspend(concurrentQueue); //将队列挂起
    
    dispatch_async(concurrentQueue, ^{
        NSLog(@"任务执行");
    });
    [self currentThreadSleep:2];
    dispatch_resume(concurrentQueue);//将挂起的队列进行唤醒
    
}

- (void)useBarrierAsync{
    NSLog(@"给队列加栅栏");
    dispatch_queue_t concurrentQueue = [self getConcurrentQueueWithLabel:@"concurrent.queue"];
    
    for (int i = 0; i < 3; i ++) {
        dispatch_async(concurrentQueue, ^{
            [self currentThreadSleep:i];
            NSLog(@"第一批%d %@", i, [self getCurrentThread]);
        });
    }
    
    dispatch_barrier_async(concurrentQueue, ^{
        NSLog(@"第一批执行完毕后才会执行第二批%@",[self getCurrentThread]);
    });
    
    for (int i = 0; i < 3; i ++) {
        dispatch_async(concurrentQueue, ^{
            [self currentThreadSleep:i];
            NSLog(@"第二批%d %@",i, [self getCurrentThread]);
        });
    }
    
    NSLog(@"异步执行测试");
    
}




//获取当前线程
- (NSThread *)getCurrentThread{
    return [NSThread currentThread];
}
//休眠当前线程
- (void)currentThreadSleep:(NSTimeInterval)timer{
    return [NSThread sleepForTimeInterval:timer];
}
//获取主队列
- (dispatch_queue_t)getMainQueue{
    return dispatch_get_main_queue();
}
//获取全局队列
- (dispatch_queue_t)getGlobalQueue{
    return dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
}
//创建并行队列
- (dispatch_queue_t)getConcurrentQueueWithLabel:(NSString *)label{
    return dispatch_queue_create([label UTF8String], DISPATCH_QUEUE_CONCURRENT);
}
//创建串行队列
- (dispatch_queue_t)getSerialQueueWithLabel:(NSString *)label{
    return dispatch_queue_create([label UTF8String], DISPATCH_QUEUE_SERIAL);
}




- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
