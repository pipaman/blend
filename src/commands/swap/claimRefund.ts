import { Contract } from '@openzeppelin/upgrades'
import * as Utils from 'web3-utils'
import { promptAndLoadEnv, promptIfNeeded } from '../../prompt'
import { BlendEnvironment } from '../../utils/environment'
import withErrors from '../../utils/withErrors'
import { ensureAddress } from '../../utils/validators'
import { NetworkName, Address } from '../../types'


interface ClaimRefundArguments {
    network: NetworkName
    from: Address
    lockId: string
}

type CmdlineOptions = Partial<ClaimRefundArguments>

async function claimRefund(options: CmdlineOptions) {
    const env = await promptAndLoadEnv({networkInOpts: options.network})

    const swapContract = await env.getContract('BlendSwap')
    const blendAddress = await swapContract.methods.blend().call()

    const questions = await makeQuestions(env)
    const args = await promptIfNeeded(options, questions)

    await swapContract.methods.claimRefund(
        args.lockId
    ).send({from: args.from})
}

async function makeQuestions(env: BlendEnvironment) {
    const existingAccounts = await env.web3.eth.getAccounts()
    return [
        {
            type: 'list',
            name: 'from',
            message: 'Address to claim refund to',
            choices: existingAccounts,
            validate:
                async (address: Address) => existingAccounts.includes(address),
        },
        {
            type: 'input',
            name: 'lockId',
            message: 'Lock id',
        },
    ]
}

function register(program: any) {
    program
        .command('swap-claim-refund')
        .usage('swap-claim-refund')
        .description(
            'Reveal secret hash'
        )
        .option('-n, --network <network_name>', 'network to use')
        .option('--from <address>', 'address to claim refund to')
        .option('--lock-id', 'lock id')
        .action(withErrors(claimRefund))
}

export { register }
