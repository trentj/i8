from . import I8

i8 = I8()
args = i8.get_parser().parse_args()
args.fn(args)
