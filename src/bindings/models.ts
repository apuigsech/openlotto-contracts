import { OpenLotto } from './OpenLotto';

class Lottery {
    openlotto: OpenLotto | null;

    ID: number;

    Name: string;
    InitBlock: bigint;
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
        this.openlotto = null;
        this.ID = 0;

        this.Name = '';
        this.InitBlock = BigInt(0);
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

    public withID(id: number): Lottery {
        this.ID = id;
        return this;
    }

    public withOpenLotto(openlotto: OpenLotto) {
        this.openlotto = openlotto;
        return this;
    }

    public async isActive() {
        const currentBlockNumber = await this.openlotto.contract.getBlockNumber();
        return this.isActiveOnBlock(currentBlockNumber);
    }

    public isActiveOnBlock(currentBlockNumber: bigint) {
        const initBlock = this.InitBlock;
        const finiBlock = initBlock + (BigInt(this.Rounds) * BigInt(this.RoundBlocks));
        return initBlock <= currentBlockNumber && currentBlockNumber < finiBlock;
    }

    public async currentRound() {
        const currentBlockNumber = await this.openlotto.contract.getBlockNumber();
        return this.roundOnBlock(currentBlockNumber);
    }

    public roundOnBlock(currentBlockNumber: bigint) {
        if (!this.isActiveOnBlock(currentBlockNumber)) {
            return 0;
        }
        return BigInt(1) + (currentBlockNumber - this.InitBlock) / BigInt(this.RoundBlocks);
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

class Ticket {
    openlotto: OpenLotto | null;

    ID: number;

    LotteryID: number;
    LotteryRoundInit: bigint;
    LotteryRoundFini: bigint;
    NumBets: number;
    Attributes: string;

    constructor() {
        this.openlotto = null;
        this.ID = 0;

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
    public withID(id: number): Ticket {
        this.ID = id;
        return this;
    }

    public withOpenLotto(openlotto: OpenLotto) {
        this.openlotto = openlotto;
        return this;
    }
}

export { Lottery, Ticket }