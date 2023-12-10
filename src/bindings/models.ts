import { OpenLotto } from './OpenLotto';

class Model {
    openlotto: OpenLotto | null;
    ID: number;

    syncBlockNumber: number | null;

    private autoSyncInterval?: NodeJS.Timeout;

    constructor() {
        this.openlotto = null;
        this.ID = 0;
        this.syncBlockNumber = null;
    }

    public destroy() {
        if (this.autoSyncInterval) {
            clearInterval(this.autoSyncInterval);
            this.autoSyncInterval = undefined;
        }
    }

    public withID(id: number): Model {
        this.ID = id;
        return this;
    }

    public withOpenLotto(openlotto: OpenLotto): Model {
        this.openlotto = openlotto;
        return this;
    }

    public withAutoSync(freq: number = 5000): Model {
        if (freq > 0) {
            this.sync();
            this.autoSyncInterval = setInterval(() => this.sync(), freq);
        }
        return this;
    }

    public async waitForSync(): Promise<Model> {
        while(!this.isSync()) {
            await new Promise(resolve => setTimeout(resolve, 1000));
        }
        return this;
    }

    protected async sync() {
        if (this.openlotto) {
            this.syncBlockNumber = await this.openlotto.contract.runner.provider.getBlockNumber();
        }
    }

    protected isSync() {
        return (this.syncBlockNumber !== null);
    }
}

class Lottery extends Model {
    Name: string;
    InitBlock: number;
    Rounds: number;
    RoundBlocks: number;
    BetPrice: bigint;
    JackpotMin: bigint;
    DistributionPoolTo: [string, string, string, string, string];
    DistributionPoolShare: [bigint, bigint, bigint, bigint, bigint];
    PrizePoolShare: [
        bigint, bigint, bigint, bigint, bigint,
        bigint, bigint, bigint, bigint, bigint,
        bigint, bigint, bigint, bigint, bigint,
        bigint, bigint, bigint, bigint, bigint
    ];
    PrizePoolAttributes: [
        string, string, string, string, string,
        string, string, string, string, string,
        string, string, string, string, string,
        string, string, string, string, string
    ];
    Operator: string;
    Attributes: string;

    constructor() {
        super();

        this.Name = '';
        this.InitBlock = 0;
        this.Rounds = 0;
        this.RoundBlocks = 0;
        this.BetPrice = BigInt(0);
        this.JackpotMin = BigInt(0);
        this.DistributionPoolTo = [
            '0x0000000000000000000000000000000000000000',
            '0x0000000000000000000000000000000000000000',
            '0x0000000000000000000000000000000000000000',
            '0x0000000000000000000000000000000000000000',
            '0x0000000000000000000000000000000000000000'
        ];
        this.DistributionPoolShare = [
            BigInt(0), BigInt(0), BigInt(0), BigInt(0), BigInt(0)
        ];
        this.PrizePoolShare = new Array(20).fill(BigInt(0)) as [
            bigint, bigint, bigint, bigint, bigint,
            bigint, bigint, bigint, bigint, bigint,
            bigint, bigint, bigint, bigint, bigint,
            bigint, bigint, bigint, bigint, bigint
        ];
        this.PrizePoolAttributes = new Array(20).fill('0x0000000000000000') as [
            string, string, string, string, string,
            string, string, string, string, string,
            string, string, string, string, string,
            string, string, string, string, string
        ];
        this.Operator = '0x0000000000000000000000000000000000000000';
        this.Attributes = '0x00000000000000000000000000000000';
    }

    public static fromEmpty(): Lottery {
        return new Lottery();
    }

    public static fromResult(result: any): Lottery {
        let lottery = Lottery.fromEmpty();
        lottery.Name = result[0];
        lottery.InitBlock = result[1];
        lottery.Rounds = result[2];
        lottery.RoundBlocks = result[3];
        lottery.BetPrice = result[4];
        lottery.JackpotMin = result[5];

        for (let i = 0 ; i < result[6].length ; i++) {
            lottery.DistributionPoolTo[i] = result[6][i];
        }

        for (let i = 0 ; i < result[7].length ; i++) {
            lottery.DistributionPoolShare[i] = result[7][i];
        }

        for (let i = 0 ; i < result[8].length ; i++) {
            lottery.PrizePoolShare[i] = result[8][i];
        }

        for (let i = 0 ; i < result[9].length ; i++) {
            lottery.PrizePoolAttributes[i] = result[9][i];
        }

        lottery.Operator = result[10];
        lottery.Attributes = result[11];

        return lottery;
    }

    protected async sync() {
        super.sync();
    }

    public isActive() {
        if (this.isSync()) {
            const blockNumber = this.syncBlockNumber;
            return this.isActiveOnBlock(blockNumber);
        } else {
            throw new Error("Not synchronized");
        }
    }

    public isActiveOnBlock(blockNumber: number) {
        const initBlock = this.InitBlock;
        const finiBlock = initBlock + (this.Rounds * this.RoundBlocks);
        return initBlock <= blockNumber && blockNumber < finiBlock;
    }

    public async currentRound() {
        const blockNumber = await this.syncBlockNumber;
        return this.roundOnBlock(blockNumber);
    }

    public roundOnBlock(blockNumber: number) {
        if (!this.isActiveOnBlock(blockNumber)) {
            return 0;
        }
        return Math.floor(1 + (blockNumber - Number(this.InitBlock)) / Number(this.RoundBlocks));
    }

    public async reserve() {
        if (this.ID == 0 || this.openlotto == null) {
            return 0;
        }

        return await this.openlotto.contract.GetReserve(this.ID);
    }

    public async roundJackPot(round: number) {
        if (this.ID == 0 || this.openlotto == null) {
            return 0;
        }

        return await this.openlotto.contract.GetRoundJackpot(this.ID, round);
    }
}

class Ticket extends Model {
    LotteryID: number;
    LotteryRoundInit: bigint;
    LotteryRoundFini: bigint;
    NumBets: number;
    Attributes: string;

    constructor() {
        super();

        this.LotteryID = 0;
        this.LotteryRoundInit = BigInt(0);
        this.LotteryRoundFini = BigInt(0);
        this.NumBets = 0;
        this.Attributes = '0x0000000000000000';
    }

    public static fromEmpty(): Ticket {
        return new Ticket();
    }

    public static fromResult(result: any): Ticket {
        let ticket = Ticket.fromEmpty();
   
        ticket.LotteryID = result[0];
        ticket.LotteryRoundInit = result[1];
        ticket.LotteryRoundFini = result[2];
        ticket.NumBets = result[3];
        ticket.Attributes = result[4];
        
        return ticket;
    }
    protected async sync() {
        super.sync();
        console.log("lottery sync");
    }
}

export { Lottery, Ticket }