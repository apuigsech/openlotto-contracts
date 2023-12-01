import { JsonRpcProvider, HDNodeWallet, Mnemonic } from "ethers";
import { execSync, spawn } from "child_process";

import { OpenLotto, Lottery, Ticket } from '../../src/bindings/OpenLotto';

function stall(duration) {
    return new Promise((resolve) => { setTimeout(resolve, duration); });
}

function newFilledLottery(operator): Lottery {
    let lottery = OpenLotto.NewEmptyLottery();
    lottery.Name = 'dummy';
    lottery.InitBlock = BigInt('10');
    lottery.Rounds = 10;
    lottery.RoundBlocks = 100;
    lottery.BetPrice = BigInt('10000000000000000');
    lottery.PrizePoolShare[0] = BigInt('1000000000000000000');
    lottery.Operator = operator;
    return lottery;
}
  
function newFilledTicket(): Ticket {
    let ticket = OpenLotto.NewEmptyTicket();
    ticket.LotteryID = 1;
    ticket.LotteryRoundInit = BigInt('1');
    ticket.LotteryRoundFini = BigInt('1');
    ticket.NumBets = 1;
    return ticket;
}

class TestProvider extends JsonRpcProvider {
    constructor(port?: number, fork?: JsonRpcProvider) {
        if (!port) {
            port = Math.floor(Math.random() * 10000) + 10000;
        }
        let args = ['--silent', '-p', `${port}`];
        if (fork) {
            args.push('-f', `${fork._getConnection().url}`);
        }
        super(`http://localhost:${port}`);
        this['subprocess'] = spawn('anvil', args);
    }

    async wait(time) {
        await stall(time);
        while (true) {
            try {
                await this.send('eth_chainId', []);
                break;
            } catch (error) {
                continue;
            }
        }
    }

    async destroy() {
        super.destroy();
        this['subprocess'].kill();
    }
    
    async runForgeScript(script: string, privkey: string) {
        const url = this._getConnection().url;
        const cmd = `forge script ${script} --rpc-url ${url} --private-key ${privkey} --broadcast`;
        execSync(cmd);
    }
}

function newWallet(provider: JsonRpcProvider, mnemonic: string, index: number) { 
    const path = `m/44'/60'/0'/0/${index}`;
    const signer = HDNodeWallet.fromMnemonic(Mnemonic.fromPhrase(mnemonic), path);
    return signer.connect(provider);
}

export {
    newFilledLottery,
    newFilledTicket,
    TestProvider,
    newWallet
};

