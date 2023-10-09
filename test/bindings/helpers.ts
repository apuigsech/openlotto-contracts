import { JsonRpcProvider, HDNodeWallet, Mnemonic } from "ethers";
import { exec } from "child_process";

import { OpenLotto, LotteryItem, TicketItem } from '../../src/bindings/OpenLotto.ts';

function newFilledLottery(operator): LotteryItem {
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
  
function newFilledTicket(): TicketItem {
    let ticket = OpenLotto.NewEmptyTicket();
    ticket.LotteryID = 1;
    ticket.LotteryRoundInit = BigInt('1');
    ticket.LotteryRoundFini = BigInt('1');
    ticket.NumBets = 1;
    return ticket;
}

async function newTestJsonRpcProvider(port?: number, forkUrl?: string): Promise<JsonRpcProvider> {
    if (!port) {
        port = Math.floor(Math.random() * 10000) + 10000;
    }
    let cmd = `anvil --silent -p ${port}`;
    if (forkUrl) {
        cmd += ` -f ${forkUrl}`;
    }
    const url = `http://localhost:${port}`
    const provider = new JsonRpcProvider(url);
    provider['subprocess'] = exec(cmd);
    provider['subprocess'].unref();
    while (true) {
        try {
            await provider.send('eth_chainId', []);
            break;
        } catch (error) {
            continue;
        }
    }
    return provider;
}

async function runForgeScript(provider: JsonRpcProvider, script: string, privkey: string) {
    const url = provider._getConnection().url;
    const cmd = `forge script ${script} --rpc-url ${url} --private-key ${privkey} --broadcast`;
    let process = exec(cmd, (error, stdout, stderr) => {
        console.log(stdout);
        console.log(stderr);
    });
    process.unref();
    await new Promise((resolve, reject) => {
        process.on('exit', resolve);
        process.on('error', reject);
    });
}

function newWallet(provider: JsonRpcProvider, mnemonic: string, index: number) { 
    const path = `m/44'/60'/0'/0/${index}`;
    const signer = HDNodeWallet.fromMnemonic(Mnemonic.fromPhrase(mnemonic), path);
    return signer.connect(provider);
}

export {
    newFilledLottery,
    newFilledTicket,
    newTestJsonRpcProvider,
    runForgeScript,
    newWallet
};
