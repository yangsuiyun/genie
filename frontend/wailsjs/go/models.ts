export namespace main {
	
	export class TimerStatus {
	    state: string;
	    remainingTime: number;
	    currentCycle: number;
	    completedPomodoros: number;
	
	    static createFrom(source: any = {}) {
	        return new TimerStatus(source);
	    }
	
	    constructor(source: any = {}) {
	        if ('string' === typeof source) source = JSON.parse(source);
	        this.state = source["state"];
	        this.remainingTime = source["remainingTime"];
	        this.currentCycle = source["currentCycle"];
	        this.completedPomodoros = source["completedPomodoros"];
	    }
	}

}

