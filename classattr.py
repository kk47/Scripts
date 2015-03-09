#!/usr/bin/env python
# class attribute test

class Test:
    count = 0
    
    def __init__(self):
        data = 0
        self.data = data
        self.__class__.count += 1

    def start(self):
        self.data +=1
        self.__class__.count += 10

    def stop(self):
        print "data is %d" % self.data
        print "count is %d " % self.__class__.count

if __name__ == "__main__":
    c = Test()
    print "data is %d " % c.data
    print "count is %d " % c.count
    b = Test()
    b.start()
    c.stop()
